-- ============================================
-- FIX: Private profile rows world-readable (PII leak)
-- ============================================
-- Live proof (2026-08-05):
-- GET /rest/v1/profiles?id=eq.<victim> with the published anon key
-- returns full profile rows even when public_profile=false, including
-- email, first_name, last_name, height, and weight.
--
-- Root cause: setup SQL created
--   CREATE POLICY "Users can read other profiles" ... USING (true);
-- Friends/privacy migrations that intended
--   public_profile = true OR id = auth.uid()
-- never replaced the open policy on production (OR of policies = open).
--
-- Product copy (ProfileSettingsView): when Public Profile is OFF,
-- "Only friends can see your profile".
--
-- Access model after this fix:
-- - public_profile = true → readable by anon + authenticated
-- - own row → always readable
-- - friendship participant (pending or accepted) → readable
-- - shared challenge membership → readable (leaderboards / group UI)
-- - otherwise → hidden
--
-- Also revokes client UPDATE on is_premium and total_steps (proven
-- writable via PATCH on live; SECURITY DEFINER sync RPCs still work).
--
-- Deploy in Supabase SQL Editor after review.
-- ============================================

-- Helper bypasses challenge_members / friendships RLS so co-member
-- and friend checks are not false-negatives under invoker RLS.
CREATE OR REPLACE FUNCTION public.is_profile_viewer_allowed(target UUID)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT
    target IS NOT NULL
    AND auth.uid() IS NOT NULL
    AND (
      target = auth.uid()
      OR EXISTS (
        SELECT 1
        FROM public.friendships f
        WHERE (f.requester_id = auth.uid() AND f.addressee_id = target)
           OR (f.addressee_id = auth.uid() AND f.requester_id = target)
      )
      OR EXISTS (
        SELECT 1
        FROM public.challenge_members me
        JOIN public.challenge_members other
          ON other.challenge_id = me.challenge_id
        WHERE me.user_id = auth.uid()
          AND other.user_id = target
      )
    );
$$;

REVOKE ALL ON FUNCTION public.is_profile_viewer_allowed(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_profile_viewer_allowed(UUID) TO authenticated, anon;

COMMENT ON FUNCTION public.is_profile_viewer_allowed(UUID) IS
  'SECURITY DEFINER helper for profiles SELECT RLS: self, friendship, or shared challenge membership.';

-- Drop known permissive / superseded SELECT policies
DROP POLICY IF EXISTS "Users can read other profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can read own profile" ON public.profiles;
DROP POLICY IF EXISTS "read public profiles or self" ON public.profiles;
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.profiles;
DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON public.profiles;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.profiles;
DROP POLICY IF EXISTS "profiles_select_scoped" ON public.profiles;

CREATE POLICY "profiles_select_scoped"
ON public.profiles
FOR SELECT
USING (
  public_profile = TRUE
  OR public.is_profile_viewer_allowed(id)
);

COMMENT ON POLICY "profiles_select_scoped" ON public.profiles IS
  'Public profiles are world-readable; private profiles only for self, friends, or challenge co-members.';

-- Harden privileged profile columns (client must not self-grant premium
-- or forge lifetime step totals). DEFINER functions still update as owner.
REVOKE UPDATE (is_premium) ON public.profiles FROM authenticated, anon;
REVOKE UPDATE (total_steps) ON public.profiles FROM authenticated, anon;

COMMENT ON COLUMN public.profiles.is_premium IS
  'Server-managed entitlement flag. Clients cannot UPDATE this column.';
COMMENT ON COLUMN public.profiles.total_steps IS
  'Aggregated steps maintained by sync RPCs. Clients cannot UPDATE this column.';
