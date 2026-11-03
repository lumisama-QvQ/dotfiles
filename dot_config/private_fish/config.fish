set -g fish_greeting ''
if status is-interactive
    if not test -e /run/.containerenv
        abbr sudo sudo-rs
    else
        fish_add_path $HOME/.cargo/bin
    end
    # Commands to run in interactive sessions can go here
end
