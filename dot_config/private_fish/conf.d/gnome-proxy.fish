# ~/.config/fish/conf.d/gnome-proxy.fish

# ---- 容器检测 ----
function __in_container
    # Docker
    test -f /.dockerenv; and return 0
    # Podman
    test -f /run/.containerenv; and return 0
    # systemd-detect-virt（有就优先用，最靠谱）
    if command -q systemd-detect-virt
        systemd-detect-virt --container --quiet; and return 0
    end
    # 兜底：看 PID 1 的 cgroup 有没有容器痕迹
    if test -r /proc/1/cgroup
        string match -q -r '(docker|lxc|kubepods|containerd|podman)' </proc/1/cgroup; and return 0
    end
    return 1
end

# ---- 不在容器里才挂载代理同步 ----
if not __in_container
    function sync_gnome_proxy --on-event fish_prompt
        set -l mode (gsettings get org.gnome.system.proxy mode 2>/dev/null | string trim --chars="'")

        if test "$mode" = manual
            set -l http_host (gsettings get org.gnome.system.proxy.http host 2>/dev/null | string trim --chars="'")
            set -l http_port (gsettings get org.gnome.system.proxy.http port 2>/dev/null)

            set -l proxy_url ""
            if test -n "$http_host"; and test "$http_port" -gt 0
                set proxy_url "http://$http_host:$http_port"
            end

            if test -n "$proxy_url"
                set -gx http_proxy "$proxy_url"
                set -gx https_proxy "$proxy_url"
                set -gx HTTP_PROXY "$http_proxy"
                set -gx HTTPS_PROXY "$https_proxy"
                set -gx all_proxy "$proxy_url"
                set -gx ALL_PROXY "$all_proxy"
            end

            set -l ignore_hosts (gsettings get org.gnome.system.proxy ignore-hosts 2>/dev/null | string trim --chars="[]'" | string replace -a ", " ",")
            if test -n "$ignore_hosts"
                set -gx no_proxy "$ignore_hosts"
                set -gx NO_PROXY "$no_proxy"
            else
                set -gx no_proxy "localhost,127.0.0.1,::1"
                set -gx NO_PROXY "$no_proxy"
            end
        else
            set -e http_proxy https_proxy HTTP_PROXY HTTPS_PROXY all_proxy ALL_PROXY no_proxy NO_PROXY
        end
    end
end
