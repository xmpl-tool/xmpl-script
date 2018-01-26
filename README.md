# xmpl-script
xmpl-tool is a simple script created for fast searching, fetching, and executing examples of Linux commands from online, or local command repositories.

The tool uses GitHub as the repository backend, giving the community the ability to update the repository with new commands and usage examples.

## Installation

```bash
git clone https://github.com/xmpl-tool/xmpl-script.git
cd xmpl-script
sudo bash xmpl.sh -I
```

## Full usage
```
  xmpl                                  List available packages

        [<query>]                       Search all examples with query

        -s [<query>]                    Search examples with query
        -p [package]                    Filter by package

        -c                              Display comments in examples

        -o                              Force online working mode
        -O                              Force online working mode with descriptions

        -i [<arguments>]                Input mode
        -x [<arguments>]                Execute mode

        -l                              Show last selected example
        -X [<arguments>]                Execute last selected example

        -I                              Install on local system
        -U                              Uninstall from local system

        -N [github_user/repo]           Add new private repository
        -D [repo_alias]                 Delete local repository

        -r [repo_alias]                 Switch repository source
        -R [repo_alias]                 Switch and store repository source

        -e [package]                    Edit package in private repository

        -S [repo_alias]                 Synchronize local repository with GitHub repository
        -P [repo_alias]                 Send changes to xmpl main repository

        -? / -h                         Show xmpl help page
```
