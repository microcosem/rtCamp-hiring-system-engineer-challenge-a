# rtCamp: System Engineer Assignment

Hello rtCamp review team and the rest of the world! This project is my submission for [Challenge A: A Web Server Setup for WordPress](https://github.com/rtCamp/hiring-assignments/tree/master/System-Engineer#challenge-a-web-server-setup-for-wordpress) for the System Engineer position at [rtCamp](https://rtcamp.com/).

# Running

In addition to writing the provisioner in Bash, I've also provided two different ways to run it. 

1. **Manual provisioning:** For a more granular exploration of the script, the tester may want to use the [manual provisioning](#manual-provisioning) method instead, which exemplifies the prompt for the user to enter their own domain, as was specifically requested in the assignment.
1. **Automatic provisioning** - To exemplify a more automated way of using the provisioner, I've also implemented it as a [shell provisioning script](https://www.vagrantup.com/docs/provisioning/shell.html) for a [Vagrant](https://vagrantup.com/) virtual machine. This will allow the results of the script in terms of its goal (to install WordPress) to be seen more easily, because the [automatic provisioning](#automatic-provisioning) method will also produce a graphical browser that the tester can use to verify the actual WordPress installation's success.

Specific running instructions for either method follow.

## Manual provisioning

Running the script this way will interactively prompt you to enter a domain name.

First, boot the virtual machine without the Vagrant provisioner and then SSH into it:

```sh
vagrant up --no-provision
vagrant ssh
```

Finally, run the script using:

```sh
sudo /vagrant/provision/main.sh
```

### Automatic provisioning

Since the provisioning script can also be run non-interactively, it can also be used as a provisioner for a Vagrant virtual machine. The best (fastest) way to run the script is to simply run:

```sh
vagrant up
```

Using this method, Vagrant itself passes the domain name argument as an option to the provisioning script (configured in the [`Vagrantfile`](Vagrantfile)), which bypasses the interactive prompt. By default, the domain is set to `example.com`. You can choose to provision the server for a different domain name either by editing the Vagrantfile, or [running the script manually](#manual-provisioning).

Note that the resulting output, `All done! Congrats! Go ahead and open up http://<your-domain> in a browser.` will only work with regards to a browser running on the _virtual machine_. If you do not want to install a browser, you can `vagrant ssh` into the machine and test the installation results by using `curl -I <your-domain>` to view the HTTP headers or `curl -L <your-domain>` to get the site itself.

But, if you are launching the Vagrant virtual machine on a GNU/Linux host or have already installed an X11 environment on your system, you can use the following one-line command to launch a graphical browser via a forwarded X session over SSH:

```sh
vagrant up -- sudo apt install xfce4 firefox && vagrant ssh -- -X firefox
```

This will install the XFCE desktop environment and the Firefox browser on the virtual machine, then use X11 forwarding through your Vagrant SSH connection to show you a graphical browser. In the presented graphical browser, you may then simply go to `http://example.com` (or whatever domain name you provisioned), where you'll be presented with the WordPress installation wizard.

## Known issues

* Because prompting for passwords was not an aspect of the assignment (and in the interests of time), the script currently generates a strong(ish) MySQL user password at runtime for you using `openssl` rather than prompting the system operator or providing any alternative means of providing secrets. This causes a problem if you run the script twice without first destroying and re-creating the VM, because you will have already set a password for the MySQL user account (which is not overwritten on subsequent runs) that will not match the second generated password (which is always written to the WordPress configuration file). So if you'd like to run the provisioner more than once, please make sure to run `vagrant destroy && vagrant up` after each run, regardless of whether it was run automatically or manually.
