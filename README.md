# armbian-envtemp-cpufreq

Adjust maximum CPU frequency based on environment temperature.
Works with [temphumd](https://git.ch1p.io/homekit.git/tree/src/temphumd.py) server.

## Usage

The script is supposed to be run by cron.

Crontab line example, running it every 20 minutes:
```
*/20 * * * * /usr/local/bin/armbian-envtemp-cpufreq.sh -c /etc/armbian-envtemp-cpufreq.conf >/dev/null
```

## Config example

```
# roof temphumd server
192.168.1.2:8306

# you can get available frequencies
# from /sys/devices/system/cpu/cpufreq/policy0/scaling_available_frequencies

# temp freq
21 1800000   
24 1704000
28 1608000
32 1320000
36 1080000
40 888000
```

## License

BSD-2c
