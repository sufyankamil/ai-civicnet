-- Support Chat Schema
-- Create tables for support conversations and messages

-- Support Conversations
CREATE TABLE IF NOT EXISTS public.support_conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'closed')),
    feedback TEXT, -- Added for post-chat feedback
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Ensure feedback column exists for existing tables
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='support_conversations' AND column_name='feedback') THEN
        ALTER TABLE public.support_conversations ADD COLUMN feedback TEXT;
    END IF;
END $$;

-- Support Messages
CREATE TABLE IF NOT EXISTS public.support_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES public.support_conversations(id) ON DELETE CASCADE,
    sender_type TEXT NOT NULL CHECK (sender_type IN ('user', 'bot', 'agent')),
    content TEXT NOT NULL,
    options JSONB, -- For bot options
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.support_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_messages ENABLE ROW LEVEL SECURITY;

-- Policies for support_conversations
DO $$ 
BEGIN
    DROP POLICY IF EXISTS "Users can view their own support conversations" ON public.support_conversations;
    CREATE POLICY "Users can view their own support conversations" ON public.support_conversations
        FOR SELECT USING (auth.uid() = user_id);

    DROP POLICY IF EXISTS "Users can create their own support conversations" ON public.support_conversations;
    CREATE POLICY "Users can create their own support conversations" ON public.support_conversations
        FOR INSERT WITH CHECK (auth.uid() = user_id);

    DROP POLICY IF EXISTS "Users can update their own support conversations" ON public.support_conversations;
    CREATE POLICY "Users can update their own support conversations" ON public.support_conversations
        FOR UPDATE USING (auth.uid() = user_id);
END $$;

-- Policies for support_messages
DO $$ 
BEGIN
    DROP POLICY IF EXISTS "Users can view messages of their conversations" ON public.support_messages;
    CREATE POLICY "Users can view messages of their conversations" ON public.support_messages
        FOR SELECT USING (
            EXISTS (
                SELECT 1 FROM public.support_conversations
                WHERE id = support_messages.conversation_id
                AND user_id = auth.uid()
            )
        );

    DROP POLICY IF EXISTS "Users can insert messages to their conversations" ON public.support_messages;
    CREATE POLICY "Users can insert messages to their conversations" ON public.support_messages
        FOR INSERT WITH CHECK (
            EXISTS (
                SELECT 1 FROM public.support_conversations
                WHERE id = support_messages.conversation_id
                AND user_id = auth.uid()
            )
        );
END $$;

-- Trigger to update updated_at on conversation when a message is added
CREATE OR REPLACE FUNCTION public.on_support_message_insert()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.support_conversations
    SET updated_at = NOW()
    WHERE id = NEW.conversation_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_support_message_insert ON public.support_messages;
CREATE TRIGGER on_support_message_insert
AFTER INSERT ON public.support_messages
FOR EACH ROW EXECUTE FUNCTION public.on_support_message_insert();

-- Enable Realtime for these tables
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND schemaname = 'public' 
        AND tablename = 'support_conversations'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.support_conversations;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND schemaname = 'public' 
        AND tablename = 'support_messages'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.support_messages;
    END IF;
END $$;
