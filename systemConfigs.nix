inputs: {
  default = inputs.system-manager.lib.makeSystemConfig {
    modules = [
      ./systemModules
    ];
  };
}
