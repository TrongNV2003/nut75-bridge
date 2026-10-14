# nut75-bridge

Giúp bàn phím **Weikav / HFD NUT75** gõ được trên Ubuntu 26.04 trở lên (systemd ≥ 259).

## Vấn đề

- Cắm NUT75 vào (dongle 2.4G hoặc cáp), máy vẫn nhận thiết bị nhưng gõ không ra chữ.
- Chuột và các bàn phím khác vẫn dùng bình thường.
- Trên Ubuntu 24.04 cùng bàn phím này lại gõ được.

## Nguyên nhân

Firmware của NUT75 báo số serial USB chứa ký tự rác (byte `0x7F` và `U+009C`).
Từ bản 259, `systemd-udevd` từ chối thông báo thiết bị có ký tự này. Kết quả là bàn phím
không được gán tag `seat`, và GNOME không được phép mở nó.

Kernel vẫn tạo file `/dev/input/eventN` cho bàn phím, nên vẫn đọc được phím từ đó.

## Cách fix

`nut75-bridge` là một service chạy nền với quyền root. Nó:

1. Tìm các file event của NUT75 trong `/sys/class/input`, theo ID `0c45:fef9` (dongle 2.4G),
   `0c45:880c` (cáp), hoặc theo tên có chữ `nut75`.
2. Chiếm riêng các file đó (`EVIOCGRAB`) và tạo một bàn phím ảo bằng `/dev/uinput`
   với serial rỗng.
3. Chuyển mọi phím từ NUT75 sang bàn phím ảo. Đèn Caps Lock / Num Lock thì chuyển ngược lại.

udev và GNOME nhận bàn phím ảo bình thường. Script tự nhận khi cắm hoặc rút bàn phím.
Nó viết bằng Python thuần, không cần cài thêm thư viện.

## Các file

| File | Nội dung |
|---|---|
| `nut75-bridge` | Script chính, cài vào `/usr/local/bin/` |
| `nut75-bridge.service` | Unit systemd, cài vào `/etc/systemd/system/` |
| `install.sh` | Cài hoặc gỡ service |

## Cài đặt

Nên giữ một bàn phím khác cắm sẵn để gõ mật khẩu sudo.

```bash
sudo ~/nut75-bridge/install.sh
```

Sau đó cắm NUT75 và chờ khoảng 1 giây là gõ được. Service tự chạy mỗi lần bật máy,
kể cả ở màn hình đăng nhập.

## Kiểm tra

```bash
systemctl status nut75-bridge
journalctl -u nut75-bridge -f
```

Log khi chạy đúng:

```
nut75-bridge started, watching 0c45:880c, 0c45:fef9
bridging /dev/input/event9 (HFD NUT75 2.4G, 0c45:fef9)
bridging /dev/input/event10 (HFD NUT75 2.4G Keyboard, 0c45:fef9)
```

## Gỡ cài đặt

```bash
sudo ~/nut75-bridge/install.sh uninstall
```

## Xử lý sự cố

**Log không có dòng `bridging`:** có thể bàn phím đang dùng ID khác. Xem ID bằng lệnh:

```bash
grep -H . /sys/class/input/event*/device/{name,id/vendor,id/product}
```

Sau đó thêm ID vào dòng `ExecStart` trong `/etc/systemd/system/nut75-bridge.service`, ví dụ
`ExecStart=/usr/local/bin/nut75-bridge 0c45:fef9 0c45:880c 1234:abcd`. Khi đã truyền ID thì
script chỉ tìm theo ID, không tìm theo tên nữa. Chạy tiếp:

```bash
sudo systemctl daemon-reload && sudo systemctl restart nut75-bridge
```

**Kiểm tra serial có ký tự rác không:**

```bash
for d in /sys/class/input/input*; do grep -qi nut75 $d/name && cat -v $d/uniq; done
```

Nếu kết quả có `^?` hoặc `M-BM-`, nghĩa là serial có ký tự rác và đây đúng là lỗi này.
