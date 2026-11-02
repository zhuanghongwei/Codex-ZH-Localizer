(() => {
  "use strict";

  if (window.__codexZhOverlay?.version === 1) {
    window.__codexZhOverlay.scan();
    return;
  }

  const exact = new Map([
    ["ChatGPT Work", "ChatGPT 工作"],
    ["New chat", "新对话"],
    ["New Chat", "新对话"],
    ["Scheduled", "定时任务"],
    ["Scheduled tasks", "定时任务"],
    ["Plugins", "插件"],
    ["Projects", "项目"],
    ["No projects", "暂无项目"],
    ["Recents", "最近"],
    ["What should we work on?", "今天要做什么？"],
    ["Work with ChatGPT", "与 ChatGPT 协作"],
    ["Message ChatGPT", "给 ChatGPT 发消息"],
    ["Message Codex", "给 Codex 发消息"],
    ["Choose project", "选择项目"],
    ["Search", "搜索"],
    ["Search chats", "搜索对话"],
    ["Search projects", "搜索项目"],
    ["Settings", "设置"],
    ["Account", "账户"],
    ["Profile", "个人资料"],
    ["Preferences", "偏好设置"],
    ["General", "通用"],
    ["Appearance", "外观"],
    ["Connections", "连接"],
    ["Language", "语言"],
    ["Theme", "主题"],
    ["Light", "浅色"],
    ["Dark", "深色"],
    ["System", "跟随系统"],
    ["Notifications", "通知"],
    ["Usage", "用量"],
    ["About", "关于"],
    ["Help", "帮助"],
    ["Feedback", "反馈"],
    ["Keyboard shortcuts", "键盘快捷键"],
    ["New project", "新建项目"],
    ["Create project", "创建项目"],
    ["Start from scratch", "从零开始"],
    ["Open folder", "打开文件夹"],
    ["Open file", "打开文件"],
    ["Select folder", "选择文件夹"],
    ["Workspace", "工作区"],
    ["Project files", "项目文件"],
    ["Project name", "项目名称"],
    ["Project", "项目"],
    ["Model", "模型"],
    ["Reasoning", "推理"],
    ["Reasoning effort", "推理强度"],
    ["Approval mode", "审批模式"],
    ["Permissions", "权限"],
    ["Network access", "网络访问"],
    ["Read only", "只读"],
    ["Workspace write", "工作区写入"],
    ["Always ask", "始终询问"],
    ["Never", "从不"],
    ["Cancel", "取消"],
    ["Save", "保存"],
    ["Save changes", "保存更改"],
    ["Done", "完成"],
    ["Close", "关闭"],
    ["Back", "返回"],
    ["Next", "下一步"],
    ["Continue", "继续"],
    ["Retry", "重试"],
    ["Try again", "重试"],
    ["Loading...", "正在加载..."],
    ["Loading", "加载中"],
    ["Send", "发送"],
    ["Stop", "停止"],
    ["Copy", "复制"],
    ["Copy link", "复制链接"],
    ["Copied", "已复制"],
    ["Add", "添加"],
    ["Add files", "添加文件"],
    ["Attach", "添加附件"],
    ["Attach files", "添加文件"],
    ["Upload", "上传"],
    ["Download", "下载"],
    ["Remove", "移除"],
    ["Delete", "删除"],
    ["Edit", "编辑"],
    ["Rename", "重命名"],
    ["Share", "分享"],
    ["Open", "打开"],
    ["Open in browser", "在浏览器中打开"],
    ["Terminal", "终端"],
    ["Review", "审查"],
    ["Changes", "更改"],
    ["Files", "文件"],
    ["Tasks", "任务"],
    ["Skills", "技能"],
    ["Automations", "自动化"],
    ["Marketplace", "应用市场"],
    ["Installed", "已安装"],
    ["Recommended", "推荐"],
    ["Create", "创建"],
    ["Archived", "已归档"],
    ["Archive", "归档"],
    ["Unarchive", "取消归档"],
    ["Pin", "置顶"],
    ["Unpin", "取消置顶"],
    ["More", "更多"],
    ["More options", "更多选项"],
    ["View all", "查看全部"],
    ["Show more", "显示更多"],
    ["Show less", "收起"],
    ["Learn more", "了解更多"],
    ["Documentation", "文档"],
    ["Status", "状态"],
    ["In progress", "进行中"],
    ["Completed", "已完成"],
    ["Failed", "失败"],
    ["Queued", "排队中"],
    ["Running", "运行中"],
    ["Waiting", "等待中"],
    ["Waiting for approval", "等待批准"],
    ["Approve", "批准"],
    ["Deny", "拒绝"],
    ["Allow", "允许"],
    ["Block", "阻止"],
    ["Today", "今天"],
    ["Yesterday", "昨天"],
    ["Just now", "刚刚"],
    ["Are you sure?", "确定吗？"],
    ["Discard", "放弃"],
    ["Discard changes", "放弃更改"],
    ["Unsaved changes", "未保存的更改"],
    ["Update", "更新"],
    ["Upgrade", "升级"],
    ["Personalization", "个性化"],
    ["Memory", "记忆"],
    ["Custom instructions", "自定义指令"],
    ["Voice", "语音"],
    ["Voice mode", "语音模式"],
    ["Data controls", "数据控制"],
    ["Privacy", "隐私"],
    ["Security", "安全"],
    ["Accessibility", "无障碍"],
    ["Ask anything", "有什么可以帮你？"],
    ["Type a message", "输入消息"],
    ["Message", "消息"],
    ["Chat", "对话"],
    ["Chats", "对话"],
    ["Home", "主页"],
    ["New", "新建"],
    ["All", "全部"],
    ["Recent", "最近"],
    ["Source", "来源"],
    ["Sources", "来源"],
    ["Citations", "引用"],
    ["Preview", "预览"],
    ["Open preview", "打开预览"],
    ["Close preview", "关闭预览"],
    ["Start a task", "开始任务"],
    ["New task", "新任务"],
    ["Create automation", "创建自动化"],
    ["Runs", "运行记录"],
    ["Run now", "立即运行"],
    ["Paused", "已暂停"],
    ["Active", "启用"],
    ["Inactive", "停用"],
    ["Enable", "启用"],
    ["Disable", "禁用"],
    ["On", "开"],
    ["Off", "关"],
    ["Check for updates", "检查更新"],
    ["Restart", "重启"],
    ["Quit", "退出"],
    ["Minimize", "最小化"],
    ["Maximize", "最大化"],
    ["Restore", "还原"],
    ["Full screen", "全屏"],
    ["Zoom in", "放大"],
    ["Zoom out", "缩小"],
    ["Reset zoom", "重置缩放"],
    ["Developer tools", "开发者工具"],
    ["Toggle developer tools", "切换开发者工具"],
    ["Find", "查找"],
    ["Undo", "撤销"],
    ["Redo", "重做"],
    ["Cut", "剪切"],
    ["Paste", "粘贴"],
    ["Select all", "全选"],
    ["File", "文件"],
    ["View", "视图"],
    ["Sign in", "登录"],
    ["Sign out", "退出登录"],
    ["Log out", "退出登录"],
    ["Create account", "创建账户"],
    ["Email", "邮箱"],
    ["Password", "密码"],
    ["Show password", "显示密码"],
    ["Remember me", "记住我"],
    ["Forgot password?", "忘记密码？"],
    ["Something went wrong", "出现错误"],
    ["An error occurred", "发生错误"],
    ["Network error", "网络错误"],
    ["Not connected", "未连接"],
    ["Connected", "已连接"],
    ["Connecting...", "正在连接..."],
    ["Disconnect", "断开连接"],
    ["Connect", "连接"],
    ["Approved", "已批准"],
    ["Denied", "已拒绝"],
    ["All chats", "所有对话"],
    ["No results", "没有结果"],
    ["No results found", "未找到结果"],
  ]);

  const patterns = [
    [/^(\d+) chats?$/, "$1 个对话"],
    [/^(\d+) projects?$/, "$1 个项目"],
    [/^(\d+) files?$/, "$1 个文件"],
    [/^(\d+) tasks?$/, "$1 个任务"],
    [/^(\d+) min(?:ute)?s? ago$/, "$1 分钟前"],
    [/^(\d+) h(?:our)?s? ago$/, "$1 小时前"],
    [/^(\d+) d(?:ay)?s? ago$/, "$1 天前"],
    [/^(\d+) selected$/, "已选择 $1 项"],
  ];

  const textSkipSelector = [
    "textarea",
    "input",
    "select",
    "pre",
    "code",
    "[contenteditable='true']",
    "[role='textbox']",
    "[data-codex-zh-skip]",
    "[data-message-author-role]",
    "article",
  ].join(",");

  let applying = false;

  function translate(value) {
    if (!value || !value.trim()) return value;
    const match = value.match(/^(\s*)([\s\S]*?)(\s*)$/);
    if (!match) return value;
    const [, leading, body, trailing] = match;
    let translated = exact.get(body);
    if (!translated) {
      for (const [pattern, replacement] of patterns) {
        if (pattern.test(body)) {
          translated = body.replace(pattern, replacement);
          break;
        }
      }
    }
    return translated ? `${leading}${translated}${trailing}` : value;
  }

  function shouldSkipText(node) {
    const parent = node.parentElement;
    return !parent || parent.closest(textSkipSelector) !== null;
  }

  function translateTextNode(node) {
    if (shouldSkipText(node)) return;
    const next = translate(node.nodeValue);
    if (next !== node.nodeValue) node.nodeValue = next;
  }

  function translateAttributes(element) {
    for (const attribute of ["aria-label", "placeholder", "title", "alt"]) {
      const value = element.getAttribute(attribute);
      if (!value) continue;
      const next = translate(value);
      if (next !== value) element.setAttribute(attribute, next);
    }
  }

  function scan(root = document.documentElement) {
    if (!root || applying) return;
    applying = true;
    try {
      if (root.nodeType === Node.TEXT_NODE) {
        translateTextNode(root);
        return;
      }
      if (root.nodeType === Node.ELEMENT_NODE) {
        translateAttributes(root);
      }
      const walker = document.createTreeWalker(
        root,
        NodeFilter.SHOW_TEXT | NodeFilter.SHOW_ELEMENT,
      );
      let node = walker.currentNode;
      while (node) {
        if (node.nodeType === Node.TEXT_NODE) {
          translateTextNode(node);
        } else if (node.nodeType === Node.ELEMENT_NODE) {
          translateAttributes(node);
        }
        node = walker.nextNode();
      }
      document.documentElement.lang = "zh-CN";
    } finally {
      applying = false;
    }
  }

  const observer = new MutationObserver((records) => {
    if (applying) return;
    for (const record of records) {
      if (record.type === "characterData") {
        translateTextNode(record.target);
      } else if (record.type === "attributes") {
        translateAttributes(record.target);
      } else {
        for (const node of record.addedNodes) scan(node);
      }
    }
  });

  function start() {
    const root = document.documentElement;
    if (!root) {
      setTimeout(start, 25);
      return;
    }

    observer.observe(root, {
      childList: true,
      subtree: true,
      characterData: true,
      attributes: true,
      attributeFilter: ["aria-label", "placeholder", "title", "alt"],
    });

    window.__codexZhOverlay = {
      version: 1,
      scan: () => scan(),
      stop: () => observer.disconnect(),
    };

    scan(root);
    setInterval(() => scan(), 2000);
  }

  start();
})();
