-- =====================================================
-- FEEDBACK BOARD SYSTEM
-- =====================================================
-- Community feedback board where users can:
-- - Create feedback posts
-- - Edit/delete their own posts
-- - Upvote/downvote others' posts
-- - Search and filter feedback
--
-- Run this in Supabase SQL Editor
-- =====================================================

-- Step 1: Create feedback_posts table
CREATE TABLE IF NOT EXISTS public.feedback_posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL CHECK (char_length(title) >= 3 AND char_length(title) <= 200),
    description TEXT NOT NULL CHECK (char_length(description) >= 10 AND char_length(description) <= 2000),
    category TEXT NOT NULL CHECK (category IN ('bug', 'feature', 'improvement', 'other')),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'under_review', 'planned', 'completed', 'declined')),
    upvotes INT NOT NULL DEFAULT 0,
    downvotes INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_feedback_posts_user_id ON public.feedback_posts(user_id);
CREATE INDEX IF NOT EXISTS idx_feedback_posts_category ON public.feedback_posts(category);
CREATE INDEX IF NOT EXISTS idx_feedback_posts_status ON public.feedback_posts(status);
CREATE INDEX IF NOT EXISTS idx_feedback_posts_created_at ON public.feedback_posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_feedback_posts_upvotes ON public.feedback_posts(upvotes DESC);
CREATE INDEX IF NOT EXISTS idx_feedback_posts_title_search ON public.feedback_posts USING gin(to_tsvector('english', title));

-- Step 2: Create feedback_votes table
CREATE TABLE IF NOT EXISTS public.feedback_votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES public.feedback_posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    vote_type TEXT NOT NULL CHECK (vote_type IN ('up', 'down')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(post_id, user_id) -- One vote per user per post
);

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_feedback_votes_post_id ON public.feedback_votes(post_id);
CREATE INDEX IF NOT EXISTS idx_feedback_votes_user_id ON public.feedback_votes(user_id);

-- Step 3: Enable RLS
ALTER TABLE public.feedback_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feedback_votes ENABLE ROW LEVEL SECURITY;

-- Step 4: RLS Policies for feedback_posts

-- Anyone authenticated can read non-deleted posts
CREATE POLICY "Anyone can read feedback posts"
ON public.feedback_posts FOR SELECT
USING (auth.uid() IS NOT NULL AND is_deleted = FALSE);

-- Anyone authenticated can create feedback posts
CREATE POLICY "Anyone can create feedback posts"
ON public.feedback_posts FOR INSERT
WITH CHECK (
    auth.uid() IS NOT NULL
    AND user_id = auth.uid()
);

-- Users can update their own posts
CREATE POLICY "Users can update own feedback posts"
ON public.feedback_posts FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Users can soft delete their own posts
CREATE POLICY "Users can delete own feedback posts"
ON public.feedback_posts FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Step 5: RLS Policies for feedback_votes

-- Anyone can read votes
CREATE POLICY "Anyone can read votes"
ON public.feedback_votes FOR SELECT
USING (auth.uid() IS NOT NULL);

-- Users can vote on posts
CREATE POLICY "Users can create votes"
ON public.feedback_votes FOR INSERT
WITH CHECK (
    auth.uid() IS NOT NULL
    AND user_id = auth.uid()
);

-- Users can update their own votes
CREATE POLICY "Users can update own votes"
ON public.feedback_votes FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Users can delete their own votes
CREATE POLICY "Users can delete own votes"
ON public.feedback_votes FOR DELETE
USING (user_id = auth.uid());

-- Step 6: Create function to update vote counts
CREATE OR REPLACE FUNCTION public.update_feedback_vote_counts()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Recalculate upvotes and downvotes for the post
    UPDATE public.feedback_posts
    SET 
        upvotes = (
            SELECT COUNT(*) 
            FROM public.feedback_votes 
            WHERE post_id = COALESCE(NEW.post_id, OLD.post_id) 
            AND vote_type = 'up'
        ),
        downvotes = (
            SELECT COUNT(*) 
            FROM public.feedback_votes 
            WHERE post_id = COALESCE(NEW.post_id, OLD.post_id) 
            AND vote_type = 'down'
        ),
        updated_at = NOW()
    WHERE id = COALESCE(NEW.post_id, OLD.post_id);
    
    RETURN COALESCE(NEW, OLD);
END;
$$;

-- Step 7: Create triggers for vote count updates
DROP TRIGGER IF EXISTS trigger_update_vote_counts_on_insert ON public.feedback_votes;
CREATE TRIGGER trigger_update_vote_counts_on_insert
AFTER INSERT ON public.feedback_votes
FOR EACH ROW
EXECUTE FUNCTION public.update_feedback_vote_counts();

DROP TRIGGER IF EXISTS trigger_update_vote_counts_on_update ON public.feedback_votes;
CREATE TRIGGER trigger_update_vote_counts_on_update
AFTER UPDATE ON public.feedback_votes
FOR EACH ROW
EXECUTE FUNCTION public.update_feedback_vote_counts();

DROP TRIGGER IF EXISTS trigger_update_vote_counts_on_delete ON public.feedback_votes;
CREATE TRIGGER trigger_update_vote_counts_on_delete
AFTER DELETE ON public.feedback_votes
FOR EACH ROW
EXECUTE FUNCTION public.update_feedback_vote_counts();

-- Step 8: Create RPC function to get feedback posts with user info and vote status
CREATE OR REPLACE FUNCTION public.get_feedback_posts(
    p_search TEXT DEFAULT NULL,
    p_category TEXT DEFAULT NULL,
    p_status TEXT DEFAULT NULL,
    p_sort_by TEXT DEFAULT 'recent', -- 'recent', 'popular', 'controversial'
    p_limit INT DEFAULT 50,
    p_offset INT DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    title TEXT,
    description TEXT,
    category TEXT,
    status TEXT,
    upvotes INT,
    downvotes INT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    author_username TEXT,
    author_display_name TEXT,
    author_avatar_url TEXT,
    user_vote TEXT, -- 'up', 'down', or NULL
    is_author BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        fp.id,
        fp.user_id,
        fp.title,
        fp.description,
        fp.category,
        fp.status,
        fp.upvotes,
        fp.downvotes,
        fp.created_at,
        fp.updated_at,
        p.username AS author_username,
        p.display_name AS author_display_name,
        p.avatar_url AS author_avatar_url,
        fv.vote_type AS user_vote,
        (fp.user_id = auth.uid()) AS is_author
    FROM public.feedback_posts fp
    LEFT JOIN public.profiles p ON fp.user_id = p.id
    LEFT JOIN public.feedback_votes fv ON fp.id = fv.post_id AND fv.user_id = auth.uid()
    WHERE fp.is_deleted = FALSE
        AND (p_search IS NULL OR fp.title ILIKE '%' || p_search || '%' OR fp.description ILIKE '%' || p_search || '%')
        AND (p_category IS NULL OR fp.category = p_category)
        AND (p_status IS NULL OR fp.status = p_status)
    ORDER BY
        CASE 
            WHEN p_sort_by = 'recent' THEN fp.created_at
        END DESC,
        CASE 
            WHEN p_sort_by = 'popular' THEN (fp.upvotes - fp.downvotes)
        END DESC,
        CASE 
            WHEN p_sort_by = 'controversial' THEN LEAST(fp.upvotes, fp.downvotes)
        END DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_feedback_posts TO authenticated;

-- Step 9: Create RPC function to vote on feedback
CREATE OR REPLACE FUNCTION public.vote_on_feedback(
    p_post_id UUID,
    p_vote_type TEXT -- 'up', 'down', or 'remove'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_result JSON;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    -- Validate vote type
    IF p_vote_type NOT IN ('up', 'down', 'remove') THEN
        RAISE EXCEPTION 'Invalid vote type. Must be up, down, or remove';
    END IF;

    -- Check if post exists
    IF NOT EXISTS (SELECT 1 FROM public.feedback_posts WHERE id = p_post_id AND is_deleted = FALSE) THEN
        RAISE EXCEPTION 'Feedback post not found';
    END IF;

    -- Check if user is the author (can't vote on own post)
    IF EXISTS (SELECT 1 FROM public.feedback_posts WHERE id = p_post_id AND user_id = v_user_id) THEN
        RAISE EXCEPTION 'Cannot vote on your own feedback post';
    END IF;

    -- Remove vote
    IF p_vote_type = 'remove' THEN
        DELETE FROM public.feedback_votes
        WHERE post_id = p_post_id AND user_id = v_user_id;
        
        v_result := json_build_object(
            'success', true,
            'action', 'removed',
            'message', 'Vote removed'
        );
        RETURN v_result;
    END IF;

    -- Insert or update vote
    INSERT INTO public.feedback_votes (post_id, user_id, vote_type)
    VALUES (p_post_id, v_user_id, p_vote_type)
    ON CONFLICT (post_id, user_id)
    DO UPDATE SET vote_type = EXCLUDED.vote_type, created_at = NOW();

    v_result := json_build_object(
        'success', true,
        'action', 'voted',
        'vote_type', p_vote_type,
        'message', 'Vote recorded'
    );
    
    RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.vote_on_feedback TO authenticated;

-- Step 10: Create RPC function to delete feedback post (soft delete)
CREATE OR REPLACE FUNCTION public.delete_feedback_post(
    p_post_id UUID
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_result JSON;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    -- Check if post exists and user is the author
    IF NOT EXISTS (
        SELECT 1 FROM public.feedback_posts 
        WHERE id = p_post_id 
        AND user_id = v_user_id 
        AND is_deleted = FALSE
    ) THEN
        RAISE EXCEPTION 'Feedback post not found or you do not have permission to delete it';
    END IF;

    -- Soft delete the post
    UPDATE public.feedback_posts
    SET is_deleted = TRUE, updated_at = NOW()
    WHERE id = p_post_id AND user_id = v_user_id;

    v_result := json_build_object(
        'success', true,
        'message', 'Feedback post deleted'
    );
    
    RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.delete_feedback_post TO authenticated;

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Verify tables were created
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('feedback_posts', 'feedback_votes');

-- Verify indexes
SELECT indexname 
FROM pg_indexes 
WHERE tablename IN ('feedback_posts', 'feedback_votes')
ORDER BY tablename, indexname;

-- Verify RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('feedback_posts', 'feedback_votes');

-- Verify functions
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN ('get_feedback_posts', 'vote_on_feedback', 'delete_feedback_post');

-- Test the get_feedback_posts function
SELECT * FROM public.get_feedback_posts(NULL, NULL, NULL, 'recent', 10, 0);

DO $$
BEGIN
    RAISE NOTICE '✅ Feedback Board system successfully installed!';
    RAISE NOTICE 'Categories: bug, feature, improvement, other';
    RAISE NOTICE 'Statuses: pending, under_review, planned, completed, declined';
    RAISE NOTICE 'Users can create, edit, and delete their own posts';
    RAISE NOTICE 'Users can upvote/downvote others posts';
    RAISE NOTICE 'Search functionality included in get_feedback_posts()';
END $$;

