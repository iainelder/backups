# systemd

## 2023-03-30

### Learn about systemd service types

#### Test all the service types

I discovered systemd while configuring [Borgmatic](BorgBase.md).

Work with a minimal service definition to learn how the types work.

* Valid command: `sleep 5`
* Invalid command: `icantgetnosleep`
* Service types: `simple`, `exec`, `dbus`, `notify`, `idle`

There is one test case for each of the cartesian product of the command types and the service types.

Generate a service file for each test case.

```bash
cdtemp

cat > write_dummy_service <<"EOF"
#!/bin/bash

set -euxo pipefail

command_type="${1}"
command="${2}"
service_type="${3}"

cd /home/isme/.config/systemd/user/

cat > dummy-"$command_type"-"$service_type".service << SUB
[Service]
Type=${service_type}
ExecStart=${command}
SUB
EOF

chmod +x write_dummy_service

parallel write_dummy_service \
::: "valid" "invalid" \
:::+ "sleep 5" "icantgetnosleep" \
::: "simple" "exec" "forking" "oneshot" "dbus" "notify" "idle"
```

Check what has just been generated.

```console
$ systemctl --user list-unit-files "dummy-*"
UNIT FILE                     STATE  VENDOR PRESET
dummy-invalid-dbus.service    static enabled      
dummy-invalid-exec.service    static enabled      
dummy-invalid-forking.service static enabled      
dummy-invalid-idle.service    static enabled      
dummy-invalid-notify.service  static enabled      
dummy-invalid-oneshot.service static enabled      
dummy-invalid-simple.service  static enabled      
dummy-valid-dbus.service      static enabled      
dummy-valid-exec.service      static enabled      
dummy-valid-forking.service   static enabled      
dummy-valid-idle.service      static enabled      
dummy-valid-notify.service    static enabled      
dummy-valid-oneshot.service   static enabled      
dummy-valid-simple.service    static enabled      

14 unit files listed.
```

Type out each `systemctl start` command and each `journalctl` command by hand to understand the behavior. See Appendix for a console listing for all test cases.

All the service types for an invalid command appear to fail in the same way: quickly (real time under 10ms), with a generic error message from systemctl (`bad unit file setting`), and with a detailed error message in the journal (`Executable "..." not found in path "..."`).

The service types for a valid command start to show different behavior.

`exec`, `idle`, and `simple` succeed in the same way. systemctl returns quickly. The journal logs an event sequence of "Started", "Succeeded".

`forking` pauses systemctl until the command completes. The journal logs an event sequence of "Starting", "Succeeded", "Started".

`oneshot` pauses systemctl until the command completes. The journal logs an event sequence of "Starting", "Succeeded", "Finished".

`dbus` fails quickly in systemctl with a generic error and the journal shows that a "D-Bus service name" is unspecified.

`notify` pauses systemctl until the command completes, then fails with a error about the service missing a required step. The journal logs a "protocol" error.

#### Read all the service type descriptions

So I know how they behave in practice with a minimal service configuration. Now I read the documetation to see how it fits what I've seen.

From `man systemd.service`:

> It is generally recommended to use `Type=simple` for long-running services whenever possible, as it is the simplest and fastest option. \[...\] \[I\]t is not generally recommended to use `idle` or `oneshot` for long-running services.

This part of the `simple` description doesn't match my experience. I saw the `dummy-invalid-simple` service fail.

> `systemctl start` command lines for `simple` services will report success even if the service's binary cannot be invoked successfully (for example because the selected `User=` doesn't exist, or the service binary is missing).

#### Appendix

For the invalid command I use the `cat` journal output as the least cluttered option.

For the valid commands I add a monotonic time to the journal output because the command usually runs for 5 seconds.

```console
$ time systemctl --user start dummy-invalid-dbus
Failed to start dummy-invalid-dbus.service: Unit dummy-invalid-dbus.service has a bad unit file setting.
See user logs and 'systemctl --user status dummy-invalid-dbus.service' for details.

real	0m0.007s
user	0m0.001s
sys	0m0.003s

$ journalctl --user --output=cat --no-pager --unit=dummy-invalid-dbus
/home/isme/.config/systemd/user/dummy-invalid-dbus.service:3: Executable "icantgetnosleep" not found in path "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
dummy-invalid-dbus.service: Unit configuration has fatal error, unit will not be started.

$ time systemctl --user start dummy-invalid-exec
Failed to start dummy-invalid-exec.service: Unit dummy-invalid-exec.service has a bad unit file setting.
See user logs and 'systemctl --user status dummy-invalid-exec.service' for details.

real	0m0.006s
user	0m0.000s
sys	0m0.003s

$ journalctl --user --output=cat --no-pager --unit=dummy-invalid-exec
/home/isme/.config/systemd/user/dummy-invalid-exec.service:3: Executable "icantgetnosleep" not found in path "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
dummy-invalid-exec.service: Unit configuration has fatal error, unit will not be started.

$ time systemctl --user start dummy-invalid-forking
Failed to start dummy-invalid-forking.service: Unit dummy-invalid-forking.service has a bad unit file setting.
See user logs and 'systemctl --user status dummy-invalid-forking.service' for details.

real	0m0.009s
user	0m0.005s
sys	0m0.000s

$ journalctl --user --output=cat --no-pager --unit=dummy-invalid-forking
/home/isme/.config/systemd/user/dummy-invalid-forking.service:3: Executable "icantgetnosleep" not found in path "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
dummy-invalid-forking.service: Unit configuration has fatal error, unit will not be started.

$ time systemctl --user start dummy-invalid-oneshot
Failed to start dummy-invalid-oneshot.service: Unit dummy-invalid-oneshot.service has a bad unit file setting.
See user logs and 'systemctl --user status dummy-invalid-oneshot.service' for details.

real	0m0.010s
user	0m0.002s
sys	0m0.000s

$ journalctl --user --output=cat --no-pager --unit=dummy-invalid-oneshot
/home/isme/.config/systemd/user/dummy-invalid-oneshot.service:3: Executable "icantgetnosleep" not found in path "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
dummy-invalid-oneshot.service: Unit configuration has fatal error, unit will not be started.

$ time systemctl --user start dummy-invalid-idle
Failed to start dummy-invalid-idle.service: Unit dummy-invalid-idle.service has a bad unit file setting.
See user logs and 'systemctl --user status dummy-invalid-idle.service' for details.

real	0m0.006s
user	0m0.003s
sys	0m0.000s

$ journalctl --user --output=cat --no-pager --unit=dummy-invalid-idle
/home/isme/.config/systemd/user/dummy-invalid-idle.service:3: Executable "icantgetnosleep" not found in path "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
dummy-invalid-idle.service: Unit configuration has fatal error, unit will not be started.

$ time systemctl --user start dummy-invalid-notify
Failed to start dummy-invalid-notify.service: Unit dummy-invalid-notify.service has a bad unit file setting.
See user logs and 'systemctl --user status dummy-invalid-notify.service' for details.

real	0m0.008s
user	0m0.004s
sys	0m0.000s

$ journalctl --user --output=cat --no-pager --unit=dummy-invalid-notify
/home/isme/.config/systemd/user/dummy-invalid-notify.service:3: Executable "icantgetnosleep" not found in path "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
dummy-invalid-notify.service: Unit configuration has fatal error, unit will not be started.

$ time systemctl --user start dummy-invalid-simple
Failed to start dummy-invalid-simple.service: Unit dummy-invalid-simple.service has a bad unit file setting.
See user logs and 'systemctl --user status dummy-invalid-simple.service' for details.

real	0m0.009s
user	0m0.000s
sys	0m0.005s

$ journalctl --user --output=cat --no-pager --unit=dummy-invalid-simple
/home/isme/.config/systemd/user/dummy-invalid-simple.service:3: Executable "icantgetnosleep" not found in path "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
dummy-invalid-simple.service: Unit configuration has fatal error, unit will not be started.

$ time systemctl --user start dummy-valid-dbus
Failed to start dummy-valid-dbus.service: Unit dummy-valid-dbus.service has a bad unit file setting.
See user logs and 'systemctl --user status dummy-valid-dbus.service' for details.

real	0m0.007s
user	0m0.003s
sys	0m0.002s

$ journalctl --user --output=cat --no-pager --unit=dummy-valid-dbus
dummy-valid-dbus.service: Service is of type D-Bus but no D-Bus service name has been specified. Refusing.

$ time systemctl --user start dummy-valid-exec

real	0m0.013s
user	0m0.004s
sys	0m0.001s

$ journalctl --user --no-pager --output=short-monotonic --unit=dummy-valid-exec
[84072.433004] isme-t480s systemd[1979]: Started dummy-valid-exec.service.
[84077.435335] isme-t480s systemd[1979]: dummy-valid-exec.service: Succeeded.

$ time systemctl --user start dummy-valid-idle

real	0m0.010s
user	0m0.001s
sys	0m0.007s

$ journalctl --user --no-pager --output=short-monotonic --unit=dummy-valid-idle
[84295.964380] isme-t480s systemd[1979]: Started dummy-valid-idle.service.
[84300.967750] isme-t480s systemd[1979]: dummy-valid-idle.service: Succeeded.

$ time systemctl --user start dummy-valid-forking

real	0m5.030s
user	0m0.006s
sys	0m0.001s

$ journalctl --user --output=short-monotonic --no-pager --unit=dummy-valid-forking
[89717.189949] isme-t480s systemd[1979]: Starting dummy-valid-forking.service...
[89722.196897] isme-t480s systemd[1979]: dummy-valid-forking.service: Succeeded.
[89722.203997] isme-t480s systemd[1979]: Started dummy-valid-forking.service.

$ time systemctl --user start dummy-valid-oneshot

real	0m5.026s
user	0m0.004s
sys	0m0.000s

$ journalctl --user --output=short-monotonic --no-pager --unit=dummy-valid-oneshot
[89647.930771] isme-t480s systemd[1979]: Starting dummy-valid-oneshot.service...
[89652.937939] isme-t480s systemd[1979]: dummy-valid-oneshot.service: Succeeded.
[89652.938388] isme-t480s systemd[1979]: Finished dummy-valid-oneshot.service.

$ time systemctl --user start dummy-valid-notify
Job for dummy-valid-notify.service failed because the service did not take the steps required by its unit configuration.
See "systemctl --user status dummy-valid-notify.service" and "journalctl --user -xe" for details.

real	0m5.015s
user	0m0.000s
sys	0m0.005s

$ journalctl --user --no-pager --output=short-monotonic --unit=dummy-valid-notify
[84345.376307] isme-t480s systemd[1979]: Starting dummy-valid-notify.service...
[84350.380975] isme-t480s systemd[1979]: dummy-valid-notify.service: Failed with result 'protocol'.
[84350.381658] isme-t480s systemd[1979]: Failed to start dummy-valid-notify.service.

$ time systemctl --user start dummy-valid-simple

real	0m0.017s
user	0m0.000s
sys	0m0.007s

$ journalctl --user --no-pager --output=short-monotonic --unit=dummy-valid-simple
[84399.899037] isme-t480s systemd[1979]: Started dummy-valid-simple.service.
[84404.904312] isme-t480s systemd[1979]: dummy-valid-simple.service: Succeeded.
```
