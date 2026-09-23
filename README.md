# Bài đánh giá thực tập sinh backend .NET

## Bối cảnh

Công ty phần mềm Sao Bắc đang theo dõi công việc bằng một bảng tính dùng chung. Cách làm này bắt đầu bất tiện khi có nhiều dự án: khó lọc công việc, nhãn dễ bị nhập trùng, công việc đã xóa không còn dấu vết và báo cáo phải tổng hợp bằng tay.

Sao Bắc muốn có một API nội bộ tên là WorkBoard để xử lý các việc trên. Bạn phụ trách xây dựng API này bằng ASP.NET Core.

Mỗi công việc (`work item`) thuộc một dự án (`project`), có trạng thái, mức ưu tiên, người phụ trách và nhãn. Những thay đổi cần lưu lịch sử được nêu ở từng API. Dữ liệu mẫu có cả công việc nhập từ bảng tính nên một số bản ghi chưa có lịch sử. Cấu trúc bảng và dữ liệu mẫu nằm trong file SQL đi kèm.

## Phạm vi bài làm

Bạn tự tạo solution và xây dựng WorkBoard từ đầu. Mỗi buổi làm bài kéo dài 8 giờ. Leader sẽ phát đề của buổi đó khi bắt đầu.

Công nghệ bắt buộc: **ASP.NET Core .NET 10, EF Core 10 và PostgreSQL**.

Trong giờ làm bài, bạn được dùng Google, tài liệu chính thức và Stack Overflow. Không được dùng AI, trao đổi hoặc nhận code từ người khác.

## Yêu cầu về cách viết code

Hãy tổ chức code để người khác có thể đọc và tiếp tục phát triển:

- Controller tiếp nhận HTTP request và trả response; nghiệp vụ và truy vấn được tách sang lớp phù hợp.
- Tách DTO dùng cho request/response khỏi entity dùng với EF Core.
- Đưa nghiệp vụ vào Service Layer và đăng ký dependency bằng Dependency Injection.
- Dùng class, interface và encapsulation hợp lý để mỗi lớp có trách nhiệm rõ ràng.
- Áp dụng một Design Pattern cơ bản phù hợp với bài làm. Service Layer là một lựa chọn. Nếu dùng thêm Strategy, Specification hoặc Repository, hãy thể hiện rõ chúng giúp giải quyết vấn đề nào.
- Truy vấn dữ liệu bằng EF Core; dùng async cho thao tác I/O.
- Đọc connection string từ cấu hình; không đưa thông tin nhạy cảm thật vào source code.

Có thể tổ chức bài trong một Web API project theo luồng:

```text
HTTP request → Controller → Service → EF Core/DbContext → PostgreSQL
```

## Bài cần nộp

- Toàn bộ source code.
- Một file `README.md` do bạn viết, hướng dẫn cách cấu hình database, chạy ứng dụng và địa chỉ API.
- `BAO-CAO-SAU-PHAN-1.md`, nộp sau ba ngày kể từ buổi làm Phần 1. Báo cáo trình bày những gì đã học, vấn đề đã gặp, kinh nghiệm rút ra và phần tự đánh giá.

Leader chấm qua kết quả gọi API, dữ liệu trong PostgreSQL và source code. Bài làm cần chạy đúng cả khi dữ liệu khác với dữ liệu mẫu.
