var contains = function(string, substring) {
  if (removeDiacritics(string.toLowerCase()).includes(removeDiacritics(substring.toLowerCase())))
    return true;
  return false;
};

var filterList = function(class_name, filter) {
  $("." + class_name).each(function(i, element) {
    if (contains(element.innerHTML, filter))
      element.style.display = 'block';
    else
      element.style.display = 'none';
  });
};
