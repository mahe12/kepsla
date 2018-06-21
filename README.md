#KePSLA
vnc
===
Ubuntu Core 14.04 + LXDE desktop + Firefox browser + TightVNC server + Tor browser + Tomcat. Runs as a daemon by default by using tail.

Build
-----
Include password.txt with the password for TightVNC (by default this is "password"). This must be at least 8 characters and is truncated if longer.

Usage
-----
The default password should be changed. To do so start up a container and then run `docker exec <id> bash -c "echo -e '<password>\n<password>\nn' | vncpasswd"`.

Latest Updates new
