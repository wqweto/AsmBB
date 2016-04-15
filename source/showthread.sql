select

  P.id,
  P.threadID,
  strftime('%d.%m.%Y %H:%M:%S', P.postTime, 'unixepoch') as PostTime,
  P.Content,
  U.id as UserID,
  U.nick as UserName,
  U.avatar,
  U.PostCount as UserPostCount,
  ?4 as Slug,
  (select count() from UnreadPosts UP where UP.UserID = ?5 and UP.PostID = P.id) as Unread,
  P.ReadCount

from

  Posts P

left join

  Users U on U.id = P.userID

where

  P.threadID = ?1

limit ?2
offset ?3
