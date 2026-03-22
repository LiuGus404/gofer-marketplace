-- Gofer.ai Marketplace — Chat Messages Table
-- Run this in Supabase SQL Editor (supabase.com → your project → SQL Editor)

-- 1. Create the chat_messages table
create table if not exists chat_messages (
  id bigint generated always as identity primary key,
  task_number integer not null,
  sender_username text not null,
  sender_avatar text default '',
  message text not null,
  created_at timestamptz default now()
);

-- 2. Create indexes for fast lookups
create index if not exists idx_chat_task_number on chat_messages(task_number);
create index if not exists idx_chat_created_at on chat_messages(created_at);

-- 3. Enable Row Level Security
alter table chat_messages enable row level security;

-- 4. Policy: anyone can read messages (marketplace is open)
create policy "Anyone can read messages"
  on chat_messages for select
  using (true);

-- 5. Policy: authenticated users can insert messages
create policy "Authenticated users can send messages"
  on chat_messages for insert
  with check (true);

-- 6. Enable realtime for this table
alter publication supabase_realtime add table chat_messages;
