import sys
import threading


def application(env, start_response):
    start_response("200 OK", [("Content-Type", "text/plain")])
    message = "Hello World"
    return [message.encode("utf-8")]


print("[thread=%d] main." % threading.current_thread().ident)
