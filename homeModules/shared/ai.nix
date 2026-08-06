{pkgs, inputs, lib, ...}: let 
in {
  imports = [
  ];
  home = {
    packages = with pkgs; [
      llm-agents.opencode
      llm-agents.opencode2
      unstable.opencode-desktop

      #llm-agents.pi # issues with extension loading
      unstable.pi-coding-agent
      llm-agents-cached.omp

      #llm-agents-cached.code # conflict with vscode

      unstable.nodejs
    ];
  };
}
