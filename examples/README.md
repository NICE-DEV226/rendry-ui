# Examples — projets Rendry UI

Chaque dossier numerote est un projet autonome et progressif, construit
sur `lib/rendry.rb` depuis la base. Aucune dependance croisee entre projets.

| # | Projet | Ce qu'il demontre | Lancer |
|---|--------|-------------------|--------|
| 01 | `01_static_page/` | DSL pur : tags, texte, attributs, echappement | `ruby app.rb > index.html` |
| 02 | `02_component_gallery/` | Composants custom + kit built-in, slots, variantes | `ruby app.rb > index.html` |
| 03 | `03_layout_site/` | Layout partage multi-pages (SiteLayout custom) | `ruby app.rb` |
| 04 | `04_tasks_sinatra/` | App Sinatra : vues Rendry, formulaires POST, etat serveur | `bundle exec ruby examples/04_tasks_sinatra/app.rb` (port 4567) |

`rendry.css` a la racine de `examples/` : les pages generees le reference
relativement (`../rendry.css` ou `/rendry.css` pour Sinatra).
