# eza Oh My Zsh 插件
# 功能：提供优雅、自动、简洁的 eza 现代化文件列表配置

# 检查 eza 是否安装
if ! (( $+commands[eza] )); then
    print "zsh eza plugin: eza 未安装，请先安装 eza 再使用本插件。" >&2
    return 1
fi

# 智能核心函数：自动适配场景，应用最优参数
function eza() {
    local base_args=(
        --group-directories-first  # 目录优先显示
        --icons=auto               # 自动判断是否显示图标（终端支持时显示）
        --color=auto               # 自动判断是否着色（终端支持时着色）
        --time-style=long-iso      # 时间格式标准化（如 2025-02-10 10:45:00）
    )
    
    # 若在 Git 仓库中，自动显示文件的 Git 状态
    if command git rev-parse --git-dir &>/dev/null; then
        base_args+=(--git)
    fi

    if [[ -t 1 ]]; then
        # 输出到终端：启用完整增强功能（图标、颜色等）
        command eza "${base_args[@]}" "$@"
    else
        # 输出到管道/文件：禁用装饰，确保纯文本兼容性
        command eza --color=never --icons=never --group-directories-first "$@"
    fi
}

# ==================== 基础核心别名 ====================
alias ls='eza'                       # 替代默认 ls：基础网格视图，目录优先+自动图标/颜色
alias l='eza -lbH'                   # 详细列表（主力）：权限、大小（人类可读）、时间，显示非打印字符
alias ll='eza -lbHa'                 # 完整详细列表：在 l 基础上显示所有隐藏文件
alias la='eza -a'                    # 全景视图：基础视图+显示所有隐藏文件
alias l.='eza -d .*'                 # 隐藏文件专查：仅显示隐藏文件/目录（不含普通文件）

# ==================== 树状结构别名 ====================
alias lt='eza --tree --level=2'      # 简易树状图：显示2级目录结构
alias tree='eza --tree'              # 完整树状图：递归显示所有子目录和文件

# ==================== 排序筛选别名 ====================
# 排序相关
alias lsize='eza -l --sort=size'     # 按文件大小排序（详细列表）
alias lmod='eza -l --sort=modified'  # 按修改时间排序（详细列表）
alias lext='eza -l --sort=extension' # 按扩展名排序（目录优先，详细列表）

# 过滤相关
alias lf='eza --only-files'          # 仅显示文件（排除目录）
alias ld='eza --only-dirs'           # 仅显示目录（排除文件）