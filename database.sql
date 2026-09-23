CREATE TABLE developers (
  id BIGSERIAL PRIMARY KEY,
  code VARCHAR(20) NOT NULL UNIQUE,
  full_name VARCHAR(120) NOT NULL,
  email VARCHAR(200) NOT NULL UNIQUE,
  team VARCHAR(50) NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE projects (
  id BIGSERIAL PRIMARY KEY,
  code VARCHAR(20) NOT NULL UNIQUE,
  name VARCHAR(150) NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE work_items (
  id BIGSERIAL PRIMARY KEY,
  code VARCHAR(30) NOT NULL UNIQUE,
  title VARCHAR(200) NOT NULL,
  description VARCHAR(2000),
  status VARCHAR(20) NOT NULL CHECK (status IN ('Todo','InProgress','Blocked','Done','Cancelled')),
  priority VARCHAR(20) NOT NULL CHECK (priority IN ('Low','Normal','High','Urgent')),
  project_id BIGINT NOT NULL REFERENCES projects(id),
  assignee_id BIGINT REFERENCES developers(id) ON DELETE SET NULL,
  due_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  completed_at TIMESTAMPTZ,
  is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
  deleted_at TIMESTAMPTZ,
  CONSTRAINT ck_done_completed CHECK (status <> 'Done' OR completed_at IS NOT NULL),
  CONSTRAINT ck_deleted_at CHECK (NOT is_deleted OR deleted_at IS NOT NULL)
);

CREATE TABLE labels (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE work_item_labels (
  work_item_id BIGINT NOT NULL REFERENCES work_items(id) ON DELETE CASCADE,
  label_id BIGINT NOT NULL REFERENCES labels(id),
  PRIMARY KEY (work_item_id, label_id)
);

CREATE TABLE work_item_histories (
  id BIGSERIAL PRIMARY KEY,
  work_item_id BIGINT NOT NULL REFERENCES work_items(id) ON DELETE CASCADE,
  from_status VARCHAR(20),
  to_status VARCHAR(20),
  note VARCHAR(1000),
  changed_by VARCHAR(120) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL
);

CREATE INDEX ix_work_items_status ON work_items(status) WHERE NOT is_deleted;
CREATE INDEX ix_work_items_project_created ON work_items(project_id, created_at) WHERE NOT is_deleted;
CREATE INDEX ix_work_items_assignee_status ON work_items(assignee_id, status) WHERE NOT is_deleted;

INSERT INTO developers(code, full_name, email, team, is_active) VALUES
('DEV01','Nguyễn An','an@example.test','Backend',true),
('DEV02','Trần Bình','binh@example.test','Frontend',true),
('DEV03','Lê Chi','chi@example.test','Backend',true),
('DEV04','Phạm Dũng','dung@example.test','QA',true),
('DEV05','Vũ Hà','ha@example.test','Operations',true),
('DEV06','Đỗ Khoa','khoa@example.test','Backend',false),
('DEV07','Ngô Minh','minh@example.test','Backend',true);

INSERT INTO projects(code, name, is_active) VALUES
('WEB','Cổng thông tin khách hàng',true),
('OPS','Vận hành nội bộ',true),
('MOB','Ứng dụng di động',true),
('LAB','Dự án thử nghiệm',true),
('OLD','Dự án đã đóng',false),
('NEW','Dự án mới',true);

INSERT INTO labels(name) VALUES ('backend'),('frontend'),('bug'),('urgent'),('database'),('qa');

INSERT INTO work_items(code,title,description,status,priority,project_id,assignee_id,due_at,created_at,updated_at,completed_at,is_deleted,deleted_at) VALUES
('WI-2026-000001','Sửa lỗi đăng nhập','Token hết hạn sai','InProgress','Urgent',1,1,now()-interval '2 days',now()-interval '8 days',now()-interval '7 days',NULL,false,NULL),
('WI-2026-000002','Bổ sung trang hồ sơ',NULL,'Todo','Normal',1,2,now()+interval '7 days',now()-interval '3 days',now()-interval '3 days',NULL,false,NULL),
('WI-2026-000003','Tối ưu truy vấn dashboard',NULL,'Blocked','High',1,3,now()-interval '10 days',now()-interval '20 days',now()-interval '4 days',NULL,false,NULL),
('WI-2026-000004','Rà soát luồng thanh toán',NULL,'Done','High',1,4,now()-interval '15 days',now()-interval '30 days',now()-interval '14 days',now()-interval '14 days',false,NULL),
('WI-2026-000005','Cấu hình cảnh báo CPU',NULL,'InProgress','High',2,5,now()-interval '8 days',now()-interval '12 days',now()-interval '2 days',NULL,false,NULL),
('WI-2026-000006','Dọn log cũ',NULL,'Todo','Low',2,NULL,now()-interval '40 days',now()-interval '50 days',now()-interval '50 days',NULL,false,NULL),
('WI-2026-000007','Nâng phiên bản PostgreSQL',NULL,'Todo','Urgent',2,1,now()-interval '9 days',now()-interval '15 days',now()-interval '15 days',NULL,false,NULL),
('WI-2026-000008','Tài liệu trực ca',NULL,'Done','Normal',2,5,now()-interval '2 days',now()-interval '9 days',now()-interval '3 days',now()-interval '3 days',false,NULL),
('WI-2026-000009','Crash màn hình giỏ hàng',NULL,'Blocked','Urgent',3,2,now()-interval '3 days',now()-interval '7 days',now()-interval '1 day',NULL,false,NULL),
('WI-2026-000010','Push notification',NULL,'Todo','Normal',3,NULL,now()+interval '12 days',now()-interval '2 days',now()-interval '2 days',NULL,false,NULL),
('WI-2026-000011','Deep link sản phẩm',NULL,'Cancelled','Low',3,2,NULL,now()-interval '25 days',now()-interval '20 days',NULL,false,NULL),
('WI-2026-000012','Regression release 2.0',NULL,'Done','High',3,4,now()-interval '5 days',now()-interval '18 days',now()-interval '4 days',now()-interval '4 days',false,NULL),
('WI-2026-000013','Khảo sát thư viện mới',NULL,'Todo','Low',4,NULL,NULL,now()-interval '1 day',now()-interval '1 day',NULL,false,NULL),
('WI-2026-000014','POC caching',NULL,'Done','Normal',4,3,now()-interval '6 days',now()-interval '10 days',now()-interval '5 days',now()-interval '5 days',false,NULL),
('WI-2026-000015','Item đã xoá','Không được xuất hiện','Cancelled','Normal',1,1,NULL,now()-interval '20 days',now()-interval '10 days',NULL,true,now()-interval '10 days');

INSERT INTO work_item_labels(work_item_id,label_id) VALUES
(1,1),(1,3),(1,4),(2,2),(3,1),(3,5),(4,6),(5,4),(5,5),(7,4),(7,5),(9,2),(9,3),(9,4),(12,6),(14,1);

INSERT INTO work_item_histories(work_item_id,from_status,to_status,note,changed_by,created_at) VALUES
(1,NULL,'Todo','Khởi tạo','seed',now()-interval '8 days'),
(1,'Todo','InProgress','Bắt đầu xử lý','DEV01',now()-interval '7 days'),
(3,NULL,'Todo','Khởi tạo','seed',now()-interval '20 days'),
(3,'Todo','InProgress','Bắt đầu','DEV03',now()-interval '19 days'),
(3,'InProgress','Blocked','Chờ DBA','DEV03',now()-interval '4 days');
