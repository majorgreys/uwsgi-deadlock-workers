import os
import threading
import time


def run(period):
    print(
        "[thread=%u] run: start busy loop for %s seconds."
        % (threading.current_thread().ident, period)
    )
    st = time.time()
    while time.time() < st + 5:
        pass
    print("[thread=%u] run: finished." % (threading.current_thread().ident))


t = threading.Thread(target=run, args=(5,))
t.daemon = True
t.start()
