<!--
repo name: SmartOdoo
description: The complete solution to use Odoo images with custom and enterprise addons, additional fake SMTP and create it with one command
github name: dp-myodoo
link: https://github.com/dp-myodoo/Odoo-GuideLines/tree/master/odoo_docker
logo path: 'https://github.com/dp-myodoo/Odoo-GuideLines/blob/master/odoo_docker/descripion/dockerize-icon.png'
twitter: your_username
email: dp@myodoo.pl
-->

<!-- PROJECT SHIELDS -->

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]

<!-- [![MIT License][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url] -->

<!-- PROJECT LOGO -->
<br />
<p align="center">
    <a href="https://github.com/dp-myodoo/Odoo-GuideLines/tree/master/odoo_docker/dockerize-icon.png">
        <img src="'description/dockerize-icon.png'" alt="Logo" width="80" height="80">
    </a>
    <br>
    <!-- <h3 align="center">https://github.com/dp-myodoo/Odoo-GuideLines/tree/master/odoo_docker</h3> -->
    <h1 align="center">SmartOdoo</h1>
    <p align="center">
        <a href="https://github.com/dp-myodoo/Odoo-GuideLines/tree/master/odoo_docker"><strong>Explore the docs<strong></a>
        <br />
        <br />
        <!-- <a href="//github.com/SmartOdoo/dp-myodoo">View Demo</a>
        �
        <a href="https://github.com/dp-myodoo/Odoo-GuideLines/tree/master/odoo_docker/issues">Report Bug</a>
        �
        <a href="https://github.com/dp-myodoo/Odoo-GuideLines/tree/master/odoo_docker/issues">Request Feature</a> -->
    </p>
</p>

<!-- TABLE OF CONTENTS -->

## Table of Contents

- [About the Project](#about-the-project)
  - [Used Docker Images](#used-docker-images)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
- [Usage](#usage)
- [Roadmap](#roadmap)
<!-- * [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)
- [Acknowledgements](#acknowledgements) -->

<!-- ABOUT THE PROJECT -->

## About The Project

<!-- [![Product Name Screen Shot][product-screenshot]](assets/ss.png) -->

The provided script add support for oneline compose and build Odoo Complete Solution for Odoo developers. It mimic solutions presented on [odoo.sh](https://www.odoo.sh/)

Here's why:

- Your time should be focused on creating something amazing. A project that solves a problem and helps others
- You shouldn't be doing the same tasks over and over like creating a README from scratch
- You should element DRY principles to the rest of your life :smile:

Of course, no one template will serve all projects since your needs may be different. So I'll be adding more in the near future. You may also suggest changes by forking this repo and creating a pull request or opening an issue.

A list of commonly used resources that I find helpful are listed in the acknowledgements.

<!--
### Built With
This section should list any major frameworks that you built your project using. Leave any add-ons/plugins for the acknowledgements section. Here are a few examples.
* [Bootstrap](https://getbootstrap.com)
* [JQuery](https://jquery.com)
* [Laravel](https://laravel.com)
-->

### Used Docker Images

- [Odoo](https://hub.docker.com/_/odoo)
- [PostgreSQL](https://hub.docker.com/_/postgres)
- [smtp4dev](https://hub.docker.com/r/rnwood/smtp4dev)

<!-- GETTING STARTED -->

## Getting Started

Short instruction how to run scripts

### Prerequisites

This is an example of how to list things you need to use the software and how to install them.

- docker
- docker-compose

```sh
git clone https://github.com/your_username_/Project-Name.git
sudo chmod +x docker_install.sh
sudo ./docker_install.sh
```

### Installation

1. Add permisions to use script

```sh
sudo chmod +x odoo_docker/docker_start.sh
```

2. Add permissions for your projects directory

```sh
sudo chmod 755 ~/Documents/
```

3. Run script with parameters

```sh
./docker_start.sh
```

<!-- USAGE EXAMPLES -->

## Usage

For flags and example script invoke check

```sh
./docker_start.sh --help
./docker_start.sh -h
```

```sh
Usage: ./docker_start.sh -n {project_name} [parameters...]

   Examples:
   ./docker_start.sh -n Test_Project -e -o 14.0 -p 12
   ./docker_start.sh -n Test_Project

   (M) --> Mandatory parameter
   (N) --> Need parameter

   -n, --name                 (M) (N)  Set project directory and containers names
   -o, --odoo                     (N)  Set version of Odoo
   -p, --psql                     (N)  Set version of postgreSQL
   -a, --addons                   (N)  Set addons repository HTTPS url
   -b, --branch                   (N)  Set addons repository branch
   -e, --enterprise                    Set for install enterprise modules
```

_For more examples, please refer to the [Documentation](https://github.com/dp-myodoo/Odoo-GuideLines/tree/master/odoo_docker)_

<!-- ROADMAP -->

## Roadmap

- Customize services ports from parameters
- Manage already created services (start, modify, stop, remove)
- Automatic deleting associated volumes and networks when removed
- Automatic pulls newly data from repositories after services run
- Add Grafana support

<!-- See the [open issues](SmartOdoo/issues) for a list of proposed features (and known issues). -->

<!-- CONTRIBUTING -->
<!--
## Contributing

Contributions are what make the open source community such an amazing place to be learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

-->

<!-- LICENSE -->
<!--
## License

Distributed under the MIT License. See `LICENSE` for more information.
-->

<!-- CONTACT -->
<!--
## Contact

Your Name - [@dp-myodoo](https://twitter.com/your_username) - dp@dp-myodoo

Project Link: [https://github.com/dp-myodoo/Odoo-GuideLines/tree/master/odoo_docker](https://github.com/dp-myodoo/Odoo-GuideLines/tree/master/odoo_docker)

 -->

<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->

[contributors-shield]: https://img.shields.io/github/contributors/dp-myodoo/SmartOdoo.svg?style=flat-square
[contributors-url]: https://github.com/dp-myodoo/SmartOdoo/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/dp-myodoo/SmartOdoo.svg?style=flat-square
[forks-url]: https://github.com/dp-myodoo/SmartOdoo/network/members
[stars-shield]: https://img.shields.io/github/stars/dp-myodoo/SmartOdoo.svg?style=flat-square
[stars-url]: https://github.com/dp-myodoo/SmartOdoo/stargazers
[issues-shield]: https://img.shields.io/github/issues/dp-myodoo/SmartOdoo.svg?style=flat-square
[issues-url]: https://github.com/dp-myodoo/SmartOdoo/issues
[license-shield]: https://img.shields.io/github/license/dp-myodoo/SmartOdoo.svg?style=flat-square
[license-url]: https://github.com/SmartOdoo/dp-myodoo/blob/master/LICENSE.txt
[product-screenshot]: assets/ss.png
