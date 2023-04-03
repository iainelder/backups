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

Type out each `systemctl start` command and each `journalctl` command by hand to understand the behavior. See Appendix 1 for a console listing for all test cases.

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

#### Appendix 1

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

## 2023-04-03

### Learn about systemd timers

I want to set up a dummy service that runs every minute. Learn how system timers can solve this.

First, delete all the service definitions from the previous workshop session.

```console
$ rm --verbose /home/isme/.config/systemd/user/{dummy,minimal}*
removed '/home/isme/.config/systemd/user/dummy-invalid-dbus.service'
removed '/home/isme/.config/systemd/user/dummy-invalid-exec.service'
removed '/home/isme/.config/systemd/user/dummy-invalid-forking.service'
removed '/home/isme/.config/systemd/user/dummy-invalid-idle.service'
removed '/home/isme/.config/systemd/user/dummy-invalid-notify.service'
removed '/home/isme/.config/systemd/user/dummy-invalid-oneshot.service'
removed '/home/isme/.config/systemd/user/dummy-invalid-simple.service'
removed '/home/isme/.config/systemd/user/dummy.service'
removed '/home/isme/.config/systemd/user/dummy-valid-dbus.service'
removed '/home/isme/.config/systemd/user/dummy-valid-exec.service'
removed '/home/isme/.config/systemd/user/dummy-valid-forking.service'
removed '/home/isme/.config/systemd/user/dummy-valid-idle.service'
removed '/home/isme/.config/systemd/user/dummy-valid-notify.service'
removed '/home/isme/.config/systemd/user/dummy-valid-oneshot.service'
removed '/home/isme/.config/systemd/user/dummy-valid-simple.service'
removed '/home/isme/.config/systemd/user/minimal.service'
```

The `systemd` folder in this repo contains all the systemd configuration files used in this workshop.

The new `dummy.service` file configures a minimal service that prints "Hello, world!" to the journal.

Copy the new dummy service file from this repo to the user service folder.

```console
$ cp systemd/dummy.service /home/isme/.config/systemd/user/
```

List the unit files to confirm that systemd sees it.

```console
$ systemctl --user list-unit-files "dummy.service"
UNIT FILE     STATE  VENDOR PRESET
dummy.service static enabled      

1 unit files listed.
```

Confirm that on this boot there are no logs from the dummy service.

```console
$ journalctl --user --boot --unit dummy
-- Logs begin at Tue 2023-02-21 06:02:30 CET, end at Mon 2023-04-03 18:38:49 CEST. --
-- No entries --
```

Start the dummy service and confirm that it logs a message to the journal.

```console
$ systemctl --user start dummy
$ journalctl --user --boot --unit dummy
-- Logs begin at Tue 2023-02-21 06:02:30 CET, end at Mon 2023-04-03 18:43:33 CEST. --
Apr 03 18:43:33 isme-t480s systemd[4349]: Started dummy.service.
Apr 03 18:43:33 isme-t480s printf[14718]: Hello, world!
Apr 03 18:43:33 isme-t480s systemd[4349]: dummy.service: Succeeded.
```

Now I want to configure the service to run every minute.

Read the timers man page. It's quite abstract. It has no examples.

```console
$ man systemd.timer
```

Google `systemd timer every minute`.

Read [Unix and Linux question 126786](https://unix.stackexchange.com/questions/126786/systemd-timer-every-15-minutes): systemd timer every 15 minutes. It shows the `OnCalendar` and `OnUnitActiveSec` syntax as different ways of solving the problem.

Read the `time` man page. This explains the different types of time expressions: time spans, timestamps, and calendar events.

```console
man systemd.time
```

See `systemd-analyze` man sections on the `calendar`, `timestamp` and `timespan` commands. It shows how to use them to analyze these expressions.

```console
man systemd-analyze
```

The Arch Linux wiki article [systemd/Timers](https://wiki.archlinux.org/title/systemd/Timers) is a much clearer introduction to the topic than the man pages.

A realtime timer, or wallclock timer, activates on a calendar event, like a cronjob. It uses the `OnCalendar=` syntax. 

A monotonic timer activates after a timespan relative to some named event such as system boot (`OnBootSec=`) or unit activation (`OnUnitActiveSec=`).

So there are two ways to solve the problem: either use the wallclock timer with a calendar expression for every mintute, or use a monotonic timer to to active a minute after boot and a minute after every previous activation.

List the user timers active or otherwise. There are currently none.

```console
$ systemctl --user list-timers --all
NEXT LEFT LAST PASSED UNIT ACTIVATES

0 timers listed.
```

Use systemd-analyze to test a calendar expression for every 15 minutes.

```console
$ systemd-analyze calendar --iterations=5 "*:0/15:00"
  Original form: *:0/15:00                   
Normalized form: *-*-* *:00/15:00            
    Next elapse: Mon 2023-04-03 20:00:00 CEST
       (in UTC): Mon 2023-04-03 18:00:00 UTC 
       From now: 35s left                    
       Iter. #2: Mon 2023-04-03 20:15:00 CEST
       (in UTC): Mon 2023-04-03 18:15:00 UTC 
       From now: 15min left                  
       Iter. #3: Mon 2023-04-03 20:30:00 CEST
       (in UTC): Mon 2023-04-03 18:30:00 UTC 
       From now: 30min left                  
       Iter. #4: Mon 2023-04-03 20:45:00 CEST
       (in UTC): Mon 2023-04-03 18:45:00 UTC 
       From now: 45min left                  
       Iter. #5: Mon 2023-04-03 21:00:00 CEST
       (in UTC): Mon 2023-04-03 19:00:00 UTC 
       From now: 1h 0min left                
```

Test an expression for every 1 calendar minute.

```console
$ systemd-analyze calendar --iterations=5 "*:0/1:00"
  Original form: *:0/1:00                    
Normalized form: *-*-* *:00/1:00             
    Next elapse: Mon 2023-04-03 20:03:00 CEST
       (in UTC): Mon 2023-04-03 18:03:00 UTC 
       From now: 30s left                    
       Iter. #2: Mon 2023-04-03 20:04:00 CEST
       (in UTC): Mon 2023-04-03 18:04:00 UTC 
       From now: 1min 30s left               
       Iter. #3: Mon 2023-04-03 20:05:00 CEST
       (in UTC): Mon 2023-04-03 18:05:00 UTC 
       From now: 2min 30s left               
       Iter. #4: Mon 2023-04-03 20:06:00 CEST
       (in UTC): Mon 2023-04-03 18:06:00 UTC 
       From now: 3min 30s left               
       Iter. #5: Mon 2023-04-03 20:07:00 CEST
       (in UTC): Mon 2023-04-03 18:07:00 UTC 
       From now: 4min 30s left               
```

`minutely` is a more human way of expressing the same.

```console
$ systemd-analyze calendar --iterations=5 minutely
  Original form: minutely                    
Normalized form: *-*-* *:*:00                
    Next elapse: Mon 2023-04-03 20:13:00 CEST
       (in UTC): Mon 2023-04-03 18:13:00 UTC 
       From now: 58s left                    
       Iter. #2: Mon 2023-04-03 20:14:00 CEST
       (in UTC): Mon 2023-04-03 18:14:00 UTC 
       From now: 1min 58s left               
       Iter. #3: Mon 2023-04-03 20:15:00 CEST
       (in UTC): Mon 2023-04-03 18:15:00 UTC 
       From now: 2min 58s left               
       Iter. #4: Mon 2023-04-03 20:16:00 CEST
       (in UTC): Mon 2023-04-03 18:16:00 UTC 
       From now: 3min 58s left               
       Iter. #5: Mon 2023-04-03 20:17:00 CEST
       (in UTC): Mon 2023-04-03 18:17:00 UTC 
       From now: 4min 58s left               
```

Test an expression for a 1 minute timespan.

```console
$ systemd-analyze timespan 1m
Original: 1m      
      μs: 60000000
   Human: 1min    
```

The new `calendar.timer` file configures a minimal timer to activate every calendar minute.

The new `timespan.timer` file configures a minimal timer to activate 1 elapsed minute after boot and 1 elapsed minute after every activation.

Each file is named to be descriptive and distinct. The default linkage between a timer and a service requires the name of the timer to match the service. In this setup the default timer would be called `dummy.timer`. I will copy each file to this name to test its behavior.

Set up an environment variable with the name of the user service folder to make the next examples easier to type.

```bash
dest="$HOME/.config/systemd/user"
```

Copy the calendar timer to set it as the timer for the dummy service.

```console
cp systemd/calendar.timer "$dest"/dummy.timer
```

Just copying the timer file doesn't automatically register the timer object. The `list-timers` command still shows no timers.

```console
$ systemctl --user list-timers --all
NEXT LEFT LAST PASSED UNIT ACTIVATES

0 timers listed.
```

The `list-unit-files` command does show the file.

```console
$ systemctl --user list-unit-files 'dummy.*'
UNIT FILE     STATE  VENDOR PRESET
dummy.service static enabled      
dummy.timer   static enabled      

2 unit files listed.
```

Reload the systemd configuration.

```console
$ systemctl --user daemon-reload
```

The timer still is not listed.

```console
$ systemctl --user list-timers --all
NEXT LEFT LAST PASSED UNIT ACTIVATES

0 timers listed.
```

Google `systemd load timers`.

Read [Stack Overflow question 1083537](https://askubuntu.com/questions/1083537/how-do-i-properly-install-a-systemd-timer-and-service): How do I properly install a systemd timer and service? It gives more example of starting and enabling the timer. 

Start the timer.

```console
$ systemctl --user start dummy.timer
$ systemctl --user list-timers --all
NEXT                         LEFT    LAST PASSED UNIT        ACTIVATES    
Mon 2023-04-03 22:49:00 CEST 4s left n/a  n/a    dummy.timer dummy.service

1 timers listed.
```

Wait for a few minutes to pass and check the journal.

```console
$ journalctl --user --boot --unit dummy
-- Logs begin at Tue 2023-02-21 06:02:30 CET, end at Mon 2023-04-03 22:50:00 CEST. --
Apr 03 18:43:33 isme-t480s systemd[4349]: Started dummy.service.
Apr 03 18:43:33 isme-t480s printf[14718]: Hello, world!
Apr 03 18:43:33 isme-t480s systemd[4349]: dummy.service: Succeeded.
Apr 03 22:49:18 isme-t480s systemd[4349]: Started dummy.service.
Apr 03 22:49:18 isme-t480s printf[77150]: Hello, world!
Apr 03 22:49:18 isme-t480s systemd[4349]: dummy.service: Succeeded.
Apr 03 22:50:00 isme-t480s systemd[4349]: Started dummy.service.
Apr 03 22:50:00 isme-t480s printf[77362]: Hello, world!
Apr 03 22:50:00 isme-t480s systemd[4349]: dummy.service: Succeeded.
```

Reboot to see whether the timer keeps running after the new boot.

The timer is not running after a reboot.

```console
$ systemctl --user list-timers --all
NEXT LEFT LAST PASSED UNIT ACTIVATES

0 timers listed.
```

Also enable the timer so that it may become active after boot.

When I try to enable it I get an error.

```console
$ systemctl --user enable dummy.timer
The unit files have no installation config (WantedBy=, RequiredBy=, Also=,
Alias= settings in the [Install] section, and DefaultInstance= for template
units). This means they are not meant to be enabled using systemctl.
 
Possible reasons for having this kind of units are:
• A unit may be statically enabled by being symlinked from another unit's
  .wants/ or .requires/ directory.
• A unit's purpose may be to act as a helper for some other unit which has
  a requirement dependency on it.
• A unit may be started when needed via activation (socket, path, timer,
  D-Bus, udev, scripted systemctl call, ...).
• In case of template units, the unit is meant to be enabled with some
  instance name specified.
```
