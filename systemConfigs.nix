inputs: {
  default = inputs.system-manager.lib.makeSystemConfig {
    extraSpecialArgs = {
      inherit inputs;
    }; 
    modules = [
      ./systemModules
    ];
  };
}
