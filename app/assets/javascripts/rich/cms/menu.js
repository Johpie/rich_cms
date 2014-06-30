Rich.Cms.Menu = (function() {
  var bind = function() {
    $(document).on("click", "#rich_cms_menu a.mark", Rich.Cms.Editor.mark)
  };

  var register = function() {
    RaccoonTip.register("#rich_cms_menu a.login", "#rich_cms_panel",
                        {beforeShow: function(content) { content.show(); },
                         afterHide : function(content) { content.hide(); }});
  };

  return {
    init: function() {
      bind();
      register();
    }
  };
}());