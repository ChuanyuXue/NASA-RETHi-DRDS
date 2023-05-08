import subprocess


def read_analog(ip, pin):
    return subprocess.call(["./eth32/eth32-example/recv", str(ip), str(pin)])


def write_analog(ip, pin, value):
    return subprocess.call(
        ["./eth32/eth32-example/comm",
         str(ip), str(pin),
         str(value)])
