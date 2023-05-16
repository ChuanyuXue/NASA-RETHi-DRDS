import subprocess


def read_analog(ip, pin):
    value = subprocess.run(["./eth32/eth32-example/recv", "192.168.10.99", str(pin)], capture_output=True)
    ref, volt = value.stdout.decode().replace('\n','').split(',')
    return (eval(ref), eval(volt))

def write_analog(ip, pin, value):
    return subprocess.call(
        ["./eth32/eth32-example/comm",
         str(ip), str(pin),
         str(value)])

if __name__ == '__main__':
    # write_analog("192.168.10.99", 0, 1)
    print(read_analog("192.168.10.99", 1))
