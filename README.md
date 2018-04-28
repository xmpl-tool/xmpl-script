# xmpl-tool
### v1.0.8
Xmpl tool is a simple script created for fast searching, fetching, and executing examples of Linux commands from online, or local command repositories.

The tool uses GitHub as the repository backend, giving the community the ability to update the repository with new commands and usage examples.

## Installation

```bash
git clone https://github.com/xmpl-tool/xmpl-script.git
cd xmpl-script
sudo bash xmpl.sh -I
```

## Full usage
```
 xmpl
        filter_1 filter_2
        [--search] filter_1 filter_2
        [--package] [--edit] [--editor] [--delete] package
        [--input] [--execute] [--execute-last] argument_1 argument_2
        [--new-repo] github_user/repo
        [--remove-repo] [--change-repo] [--save-repo] [--sync-repo] [--pull-request] repo_alias
        [--comments] [--raw] [--online] [--full-online] [--last] 
	[--install] [--update] [--uninstall] [--version] [--help]


 xmpl                                                      List available packages

       [<query>]                                           Search all examples with query

       -s [<query>]                 --search               Search examples with query
       -p [package]                 --package              Filter by package

       -c                           --comments             Display comments in examples
       -C			    --raw		   Display raw example

       -o                           --online               Force online mode
       -O                           --full-online          Force online mode with descriptions

       -i [<arguments>]             --input                Input mode
       -x [<arguments>]             --execute              Execute mode

       -l                           --last                 Show last selected example
       -X [<arguments>]             --execute-last         Execute last selected example

       -I                           --install              Install on local system
       -U                           --update               Update to latest version
       -D                           --uninstall            Uninstall from local system

       -n [github_user/repo]        --new-repo             Add new private repository
       -m [repo_alias]              --remove-repo          Delete local repository

       -r [repo_alias]              --change-repo          Switch repository source
       -R [repo_alias]              --save-repo            Switch and store repository source

       -e [package]                 --edit                 Edit package in private repository
       -E [package]		    --editor		   Edit multiline examples in private repository
       -d [package]		    --delete		   Delete example or package in private repository

       -S [repo_alias]              --sync-repo            Synchronize local and remote repository
       -P [repo_alias]              --pull-request         Send changes to xmpl main repository

       -v                           --version              Display version
       -? / -h                      --help                 Show xmpl help page

```
