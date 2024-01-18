## About

This repository is more or less a repository I mainly use in my own development environment and usually use it as a point of reference for future use, there's a couple services I run and backup constantly simply using cronjobs and shell scripts.

## Why

Mainly because most services don't actually have a backup script or if they do it's specifically for one method of running that service ( bare metal ), I usually run my services in a docker-compose environment, I love doing it like this and it just makes sense for me especially with self hosting multiple services, I know kubernetes is a thing but I am not a company, I am just a guy hosting some stuff :)

## How to run

Most if not all scripts have a "Requirements" script which runs to check if you have the required programs to run the script, if you don't have them then you can simply check the readme for a list providing links to any github project I depend on, you of course only need the binary, although most programs I require are super common such as `curl`, `ssh`, etc...

But if there's a program such as `gdrive` that I depend on, I will link the github repository where you can yoink the binary from.

## Contributing

If you feel like you can make my scripts better, please feel free to open a pull request, I will review it asap and merge it in if I feel like it's an improvement. I know I'm not perfect and that there are many mistakes in my scripts so I'm more than happy to have PRs!

## License

The whole project is under a [MIT LICENSE](./LICENSE), so, feel free to do whatever you want with what you find in here.