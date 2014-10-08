Drupal.locale = { 'pluralFormula': function ($n) { return Number(($n>1)); }, 'strings': {"":{"An AJAX HTTP error occurred.":"Une erreur HTTP AJAX s\u0027est produite.","HTTP Result Code: !status":"Code de statut HTTP : !status","An AJAX HTTP request terminated abnormally.":"Une requ\u00eate HTTP AJAX s\u0027est termin\u00e9e anormalement.","Debugging information follows.":"Informations de d\u00e9bogage ci-dessous.","Path: !uri":"Chemin : !uri","StatusText: !statusText":"StatusText: !statusText","ResponseText: !responseText":"ResponseText : !responseText","ReadyState: !readyState":"ReadyState : !readyState","Configure":"Configurer","Please wait...":"Veuillez patienter...","Hide":"Masquer","Show":"Afficher","Show shortcuts":"Afficher les raccourcis","Hide shortcuts":"Cacher les raccourcis","Re-order rows by numerical weight instead of dragging.":"R\u00e9-ordonner les lignes avec des poids num\u00e9riques plut\u00f4t qu\u0027en les d\u00e9pla\u00e7ant.","Show row weights":"Afficher le poids des lignes","Hide row weights":"Cacher le poids des lignes","Drag to re-order":"Cliquer-d\u00e9poser pour r\u00e9-organiser","Changes made in this table will not be saved until the form is submitted.":"Les changements effectu\u00e9s dans ce tableau ne seront pris en compte que lorsque la configuration aura \u00e9t\u00e9 enregistr\u00e9e.","Not restricted":"Non restreint","Restricted to certain pages":"R\u00e9serv\u00e9 \u00e0 certaines pages","Not customizable":"Non personnalisable","The changes to these blocks will not be saved until the \u003Cem\u003ESave blocks\u003C\/em\u003E button is clicked.":"N\u0027oubliez pas de cliquer sur \u003Cem\u003EEnregistrer les blocs\u003C\/em\u003E pour confirmer les modifications apport\u00e9es ici.","The block cannot be placed in this region.":"Le bloc ne peut pas \u00eatre plac\u00e9 dans cette r\u00e9gion.","(active tab)":"(onglet actif)","Edit":"Modifier","Disabled":"D\u00e9sactiv\u00e9","Not published":"Non publi\u00e9","Wed":"mer","Mon":"Lun","Monday":"Lundi","Tuesday":"Mardi","Wednesday":"Mercredi","Thursday":"Jeudi","Friday":"Vendredi","Tue":"mar","Customize dashboard":"Personnaliser le tableau de bord","@count days":"@count jours","@count hours":"@count heures","Select all rows in this table":"S\u00e9lectionner toutes les lignes du tableau","Deselect all rows in this table":"D\u00e9s\u00e9lectionner toutes les lignes du tableau","This permission is inherited from the authenticated user role.":"Ce droit est h\u00e9rit\u00e9e du r\u00f4le de l\u0027utilisateur authentifi\u00e9.","1 hour":"@count heure","1 day":"@count jour","Add":"Ajouter","Thu":"Jeu","Hide summary":"Masquer le r\u00e9sum\u00e9","Edit summary":"Modifier le r\u00e9sum\u00e9","New revision":"Nouvelle r\u00e9vision","No revision":"Aucune r\u00e9vision","By @name on @date":"Par @name le @date","By @name":"Par @name","Alias: @alias":"Alias : @alias","No alias":"Aucun alias","Autocomplete popup":"Popup d\u0027auto-compl\u00e9tion","Searching for matches...":"Recherche de correspondances...","Requires a title":"Titre obligatoire","Don\u0027t display post information":"Ne pas afficher les informations de la contribution","Not in menu":"Pas dans le menu","Loading":"En cours de chargement","Fri":"Ven","Next":"Suivant","@title dialog":"dialogue de @title","Aug":"ao\u00fb","Sep":"sep","Done":"Termin\u00e9","Dec":"d\u00e9c","Sunday":"Dimanche","Saturday":"Samedi","Feb":"f\u00e9v","Mar":"mar","Prev":"Pr\u00e9c.","Sat":"Sam","Sun":"Dim","January":"janvier","February":"F\u00e9vrier","March":"mars","April":"avril","May":"mai","June":"juin","July":"juillet","August":"ao\u00fbt","September":"septembre","October":"octobre","November":"novembre","December":"d\u00e9cembre","Today":"Aujourd\u0027hui","Jan":"Jan","Apr":"avr","Jun":"juin","Jul":"juil","Oct":"oct","Nov":"nov","Su":"Di","Mo":"Lu","Tu":"Ma","We":"Me","Th":"Je","Fr":"Ve","Sa":"Sa","mm\/dd\/yy":"dd\/mm\/yy","The selected file %filename cannot be uploaded. Only files with the following extensions are allowed: %extensions.":"Le fichier s\u00e9lectionn\u00e9 %filename ne peut pas \u00eatre transf\u00e9r\u00e9. Seulement les fichiers avec les extensions suivantes sont permis : %extensions."}} };;

// Global Killswitch
if (Drupal.jsEnabled) {
$(document).ready(function() {
    $("body").append($("#memcache-devel"));
  });
}
;

(function ($) {
  Drupal.Panels = Drupal.Panels || {};

  Drupal.Panels.autoAttach = function() {
    if ($.browser.msie) {
      // If IE, attach a hover event so we can see our admin links.
      $("div.panel-pane").hover(
        function() {
          $('div.panel-hide', this).addClass("panel-hide-hover"); return true;
        },
        function() {
          $('div.panel-hide', this).removeClass("panel-hide-hover"); return true;
        }
      );
      $("div.admin-links").hover(
        function() {
          $(this).addClass("admin-links-hover"); return true;
        },
        function(){
          $(this).removeClass("admin-links-hover"); return true;
        }
      );
    }
  };

  $(Drupal.Panels.autoAttach);
})(jQuery);
;
