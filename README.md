The thread state in a worker process can be in an invalid state if a thread is started the master process before uWSGI forks workers. This causes a deadlock to occur when workers are respawned.

Start the uwsgi application with gdb by using the provided Docker build:

```
docker run --rm -it (docker build -q .)
```

# Investigation

## Forking and the Python plugin

If `PyOS_AfterFork()` is called immediately following `uwsgi_fork()`, uwsgi aborts with a fatal error raised when using a debug version of cPython.

``` 
Fatal Python error: Invalid thread state for this thread
```

Add a breakpoint to `Py_FatalError`:

```
break Py_FatalError
run
where
```

The output ends with:

```
[Switching to Thread 0x7f4b8fc6c780 (LWP 17)]

Thread 2.1 "uwsgi" hit Breakpoint 1, Py_FatalError (msg=0x564bc857a140 "Invalid thread state for this thread") at Python/pythonrun.c:1689
1689        fprintf(stderr, "Fatal Python error: %s\n", msg);
(gdb) where
#0  Py_FatalError (msg=0x55f1e77c3140 "Invalid thread state for this thread") at Python/pythonrun.c:1689
#1  0x000055f1e76f39b6 in PyThreadState_Swap ()
#2  0x000055f1e76b5889 in PyEval_RestoreThread ()
#3  0x000055f1e77109ed in lock_PyThread_acquire_lock ()
#4  0x000055f1e7645323 in PyCFunction_Call ()
#5  0x000055f1e75f1ceb in PyObject_Call ()
#6  0x000055f1e75f298c in PyObject_CallFunctionObjArgs ()
#7  0x000055f1e76c054f in PyEval_EvalFrameEx ()
#8  0x000055f1e76c3921 in PyEval_EvalCodeEx ()
#9  0x000055f1e7621f98 in function_call ()
#10 0x000055f1e75f1ceb in PyObject_Call ()
#11 0x000055f1e75f1e47 in call_function_tail ()
#12 0x000055f1e75f2237 in PyObject_CallMethod ()
#13 0x000055f1e76b56f3 in PyEval_ReInitThreads ()
#14 0x000055f1e7714ee5 in PyOS_AfterFork ()
#15 0x000055f1e75bfe0b in uwsgi_python_post_uwsgi_fork ()
#16 0x000055f1e7573c4b in uwsgi_respawn_worker ()
#17 0x000055f1e75b0d2e in uwsgi_start ()
#18 0x000055f1e75b39a6 in uwsgi_setup ()
#19 0x000055f1e755ce19 in main ()
```

This call stack shows how the invalid thread state is restored once `threading._after_fork()` is called.

We can inspect the thread state by adding a breakpoint at `PyEval_RestoreThread` after `PyOS_AfterFork`:

```
break PyOS_AfterFork
end
run
break PyEval_RestoreThread
continue
print tstate->thread_id
```

The thread id of the thread being restored matches the thread id of the busy loop thread started in the master process:

```
[thread=139976154965760] run: start busy loop for 5 seconds.
....
(gdb) print tstate->thread_id
$1 = 139976154965760
```
