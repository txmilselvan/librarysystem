create database library
use library

-- create table for authors
create table authors(
author_id int primary key auto_increment,
name varchar(100) not null ,
birth_year int,
country varchar(50)
);

-- create table for books
create table books(
book_id int primary key auto_increment,
title varchar(100) not null,
author_id int,
gendre varchar(50),
pulish_year int,
copies_available int default 0,
foreign key (author_id) references authors(author_id)
);

-- create table for members
create table members(
member_id int primary key auto_increment,
mem_name varchar(100) not null,
email varchar(100) unique,
phone_no varchar(15),
join_date date
);

-- create table for loans
create table loans(
loan_id int primary key auto_increment,
member_id int,
book_id int,
buy_date date,
return_date date,
returned boolean default false,
foreign key (member_id) references members(member_id),
foreign key(book_id) references books(book_id)
);

-- create notification
create table due_notification(
notifi_id int auto_increment primary key,
book_id int not null,
member_id int not null,
loan_id int not null,
due_date date not null,
notifi_on date not null,
type enum('UPCOMING','OVERDUE') NOT NULL,
unique key uniq_loans_type (loan_id,type),
index idx_member (member_id),
index idx_book (book_id),
constraint fk_due_books
 foreign key(book_id) references books(book_id)
  on update cascade
  on delete cascade,
constraint fk_due_members
 foreign key(member_id) references members(member_id)
  on update cascade
  on delete restrict,
constraint fk_due_loans
 foreign key(loan_id) references loans(loan_id)
  on update cascade
  on delete restrict
)engine=InnoDB;

-- Insert Authors
INSERT INTO Authors (name,birth_year,country) VALUES
('J.K. Rowling', 1965, 'British'),
('George Orwell', 1903,'British'),
('Harper Lee',  1926,'American');

-- Insert Books
INSERT INTO Books (title, author_id, gendre, pulish_year,copies_available) VALUES
('Harry Potter and the Sorcerer''s Stone', 1, 'Fantasy', 1997,2),
('1984', 2, 'Dystopian', 1949,3),
('To Kill a Mockingbird', 3, 'Fiction', 1960,1);

-- Insert Members
INSERT INTO Members (mem_name, email,phone_no, join_date) VALUES
('Alice Johnson', 'alice@example.com',9360224401, '2024-01-10'),
('Bob Smith', 'bob@example.com',9845923401, '2024-02-15'),
('Charlie Brown', 'charlie@example.com',3748293748, '2024-03-20');

-- Insert Loans
INSERT INTO Loans (member_id,book_id, buy_date, return_date, returned) VALUES
(1, 1, '2025-07-01', '2025-07-08', TRUE),
(2, 2, '2025-07-05', NULL, FALSE),
(3, 3, '2025-07-07', NULL, FALSE);

-- bridge many to many tables
create table booksauthors(
book_id int,
author_id int,
primary key(book_id,author_id),
foreign key (book_id) references books(book_id),
foreign key (author_id) references authors(author_id)
);

-- insert booksauthors
insert into booksauthors (book_id,author_id) values
(1,1),
(2,1),
(3,3);

-- select query
select b.title as book_title,a.name as author_name
from booksauthors ba
join books b on ba.book_id = b.book_id
join authors a on ba.author_id = a.author_id;

-- create view table for borrowed books
create view borrowedbooks as
select l.loan_id,b.title,m.mem_name as member_name,
l.buy_date,date_add(l.buy_date, interval 14 day) as due_date
from loans l
join books b on l.book_id = b.book_id
join members m on l.member_id = m.member_id
where l.return_date is null;

-- create view table for overdue books
create view overduebook as
select l.loan_id,b.title,m.mem_name as member_name,
l.buy_date,date_add(l.buy_date, interval 14 day) as due_date
from loans l
join books b on l.book_id = b.book_id
join members m on l.member_id = m.member_id
where l.return_date is null
and date_add(l.buy_date, interval 14 day) < current_date;

-- create trigger for after insert
DELIMITER $$

create trigger trg_loans_after_insert
AFTER insert on loans
for each row
BEGIN
   DECLARE dd date;
   set dd = DATE_ADD(new.buy_date,interval 14 day);
   
   if dd = current_date + interval 2 day then
    insert ignore into due_notification
      (book_id,member_id,loan_id,due_date,notifi_on ,type)
	values (new.book_id,new.member_id,new.loan_id,dd,current_date,'UPCOMING');
   end if;
   
   if dd < current_date then
    insert ignore into due_notification
      (book_id,member_id,loan_id,due_date,notifi_on,type)
	values (new.book_id,new.member_id,new.loan_id,dd,current_date,'OVERDUE');
   END IF;
end $$

DELIMITER;

-- create trigger for after update
DELIMITER $$

create trigger trg_loans_after_update
AFTER update on loans
for each row
BEGIN

     DECLARE dd date;
    
   if new.returned = FALSE then 
      set dd = DATE_ADD(new.buy_date, interval 14 day);
      
      if dd = current_date + interval 2 day then
       insert ignore into due_notification
         (book_id,member_id,loan_id,due_date,notifi_on,type)
	   values (new.book_id,new.member_id,new.loan_id,dd,current_date,'UPCOMING');
      end if;
      
      if dd < current_date then
       insert ignore into due_notification
          (book_id,member_id,loan_id,due_date,notifi_on,type)
	   values (new.book_id,new.member_id,new.loan_id,dd,current_date,'OVERDUE');
	  end if;
   end if;
end $$

DELIMITER ;

-- create report of aggregation and JOINs
SELECT
  m.mem_name,
  COUNT(l.loan_id) AS overdue_count
FROM members m
LEFT JOIN loans l 
  ON m.member_id = l.member_id
     AND l.returned = FALSE
     AND DATE_ADD(l.buy_date, INTERVAL 14 DAY) < CURRENT_DATE
GROUP BY m.member_id, m.mem_name;


