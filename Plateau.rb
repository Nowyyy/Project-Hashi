require 'gtk3'

load "HashiGrid.rb"
load "Ile.rb"
load "Pont.rb"
load "Hypothese.rb"
load "Sauvegarde.rb"
load "Aide.rb"

$timerStop = 0
$partieStop = 0

##
# Cette classe représente le plateau du plateau du jeu 
##
class Plateau 

    # Référence sur la grille
    attr_accessor :grid

    # Constructeur du plateau 
    def initialize(nomniv, x, y, diff, chargement)
        @nomniv=nomniv
        @x=x
        @y=y
        @diff = diff
        @chargement=chargement #0 ou 1 si 1 ils s'agit d'un chargement
        $partieStop = 0
        $timerStop = 0

        # Initialisation de la grille
        @grid = HashiGrid.new(@nomniv, @diff, @x,@y)
       
         #Creation de la fenêtre
        main_window_res = "./Ressources/Glade/plateau.glade"
        builder = Gtk::Builder.new
        builder.add_from_file(main_window_res)

        @plateau = builder.get_object('plateau')
        @plateau.set_title "Hashi Game"
        @plateau.signal_connect "destroy" do 
            $partieStop = 1
            Gtk.main_quit 
        end

        @plateau.set_window_position Gtk::WindowPosition::CENTER
        css_file = Gtk::CssProvider.new
        css_file.load(data: <<-CSS)
            @import url("css/plateau_style.css");
        CSS

        #Reglage bouton pause
        boutonPause = builder.get_object('boutonPause')
        boutonPause.signal_connect('clicked'){
            @plateau.set_sensitive(false)
            $timerStop = 1
            pause = Pause.new()
        }
        @plateau.style_context.add_provider(css_file, Gtk::StyleProvider::PRIORITY_USER)
        @label_aide = builder.get_object('label_aide')
        @label_aide.style_context.add_provider(css_file, Gtk::StyleProvider::PRIORITY_USER)
        

        @aide = Aide.new(@grid)
        @label_aide.set_label("")
      

        # #Reglage du bouton indice
        boutonIndice = builder.get_object('boutonIndice')
        boutonIndice.signal_connect('clicked'){
            @label_aide.set_label(@aide.getMessageAide)
            @boxPrincipale.show_all
        }

        # #Reglage du bouton Undo
        boutonUndo = builder.get_object('boutonUndo')
       
        # #Reglage du bouton Redo
        boutonRedo = builder.get_object('boutonRedo')

        # #Reglage du bouton Hypothèse
        boutonHypo = builder.get_object('boutonHypo')
        boutonHypo.signal_connect('clicked'){
            @plateau.set_sensitive(false)
            Hypothese.new(self)
        }
        
        boutonPause.style_context.add_provider(css_file, Gtk::StyleProvider::PRIORITY_USER)
        boutonIndice.style_context.add_provider(css_file, Gtk::StyleProvider::PRIORITY_USER)
        boutonRedo.style_context.add_provider(css_file, Gtk::StyleProvider::PRIORITY_USER)
        boutonUndo.style_context.add_provider(css_file, Gtk::StyleProvider::PRIORITY_USER)
        boutonHypo.style_context.add_provider(css_file, Gtk::StyleProvider::PRIORITY_USER)
        # #Creation de la barre d'outils en haut de la fenêtre
    
        @temps = builder.get_object('temps')
        

        @boxJeu = builder.get_object('boxJeu')
        @boxJeu.style_context.add_provider(css_file, Gtk::StyleProvider::PRIORITY_USER)
        
        # @boxJeu.set_border_width(10)
        @temps = builder.get_object('temps')
       
        #  Chargement de la grille
        @grid.chargeGrille()
        @grid.chargeVoisins
        if(@chargement==1)
            Sauvegarde.charge(@grid,nomniv,diff)
        end

        @grid.expand = true 
        @grid.halign =  Gtk::Align::CENTER
        @grid.valign =  Gtk::Align::CENTER
        @grid.set_row_homogeneous(true)
        @grid.set_column_homogeneous(true)
      

        boutonUndo.signal_connect('clicked'){
           @grid.undoPrevious
        }

        boutonRedo.signal_connect('clicked'){
            @grid.redoPrevious
        }

        # ajoutGrille(grid)
        @boxJeu.add(@grid)
        @boxJeu.show_all

        #Creation et affichage de la fenêtre principale
        @boxPrincipale = builder.get_object('boxPrincipale')
        @boxPrincipale.style_context.add_provider(css_file, Gtk::StyleProvider::PRIORITY_USER)

        #Gestion du temps
        @temps.set_text("0")
        if(@chargement != 1)
            $tempsPause = 0
        end

        if(@chargement == 1)
            puts $tempsPause
        end
        $tempsFin = 0

        @plateau.show

        #Thread chronomètre
        t = Thread.new{
            while $partieStop == 0 do
                @tempsDebut = Time.now
                if( @grid.grilleFini?)
                    puts "GAGNER"
                end
                while $timerStop == 0 and $partieStop == 0 do #pause pas active ou niveau pas fini
                    
                    @temps.set_text((Time.now - @tempsDebut + $tempsPause.to_f ).round(0).to_s)
                    $tempsFin = (Time.now - @tempsDebut + $tempsPause.to_f ).round(0)
                    sleep(1)
                end

                $tempsPause = $tempsPause.to_f + (Time.now - @tempsDebut ).round(0)

                while $timerStop == 1 do
                    sleep(0.1)
                end
            end
        }
    end

    # Retourne le plateau de jeu
    def getPlateau()
        return @plateau
    end

    # Méthode responsable de la gestion d'une parti fini 
    def partiFini

        if(@grid.grilleFini?)
        
            sleep(0.5) # on attend 0.5 sec afin de voir le coup qu'on a effectuer avant l'affichage #
            @plateau.set_sensitive(false)
        
            main_window_res = "./Ressources/Glade/menu_win.glade"
            builder = Gtk::Builder.new
            builder.add_from_file(main_window_res)

            window = builder.get_object('menu_gain')
            window.set_title "VICTOIRE"
            window.set_window_position Gtk::WindowPosition::CENTER
            window.signal_connect "destroy" do 
                $partieStop = 1
                Gtk.main_quit 
            end

            css_file = Gtk::CssProvider.new
            css_file.load(data: <<-CSS)
                @import url("css/menu_pause.css");
            CSS

            window.style_context.add_provider(css_file, Gtk::StyleProvider::PRIORITY_USER)
         
            #Affichage du temps
            texteTemps = builder.get_object('texteTemps')
            texteTemps.set_markup("<span font_desc = \"Toledo 15\">Votre temps : " +  $tempsFin.to_s + " secondes.</span>\n")
            texteTemps.set_justify(Gtk::Justification::CENTER)
            
            saveBox = builder.get_object('saveBox')
    
            # #Zone de texte pour entrer son pseudo
            zonetexte= builder.get_object('zonetexte')
            zonetexte.set_placeholder_text("Votre pseudo")

            # #Bouton pour sauvegarder            
            btnSauvegarder = builder.get_object('btnSauvegarder')
            textLabel = builder.get_object("textLabel")

            btnSauvegarder.signal_connect('clicked'){
                label = zonetexte.text + "<span font_desc = \"Calibri 10\"> sauvegardé.</span>\n"
                Sauvegarde.saveTime(@nomniv, @diff, $tempsFin.to_s, zonetexte.text)
                textLabel.set_markup(label)
                btnSauvegarder.hide()
               
            }
            $timerStop=1

            # #Bouton pour recommencer la partie
            # btnRecommencer = Gtk::Button.new(:label => 'Recommencer')
            btnRecommencer = builder.get_object('btnRecommencer')
            btnRecommencer.signal_connect('clicked'){
                self.resetPlateau()
                self.getPlateau().set_sensitive(true)
                window.destroy
                Gtk.main
            }
    
            # #Bouton pour retourner au menu principal
            btnRetour =  builder.get_object('btnRetour')
            btnRetour.signal_connect('clicked'){
                window.destroy
                @plateau.destroy
                MainMenu.new
                Gtk.main
            }
            
            btnRecommencer.style_context.add_provider(css_file, Gtk::StyleProvider::PRIORITY_USER)
            btnRetour.style_context.add_provider(css_file, Gtk::StyleProvider::PRIORITY_USER)
            btnSauvegarder.style_context.add_provider(css_file, Gtk::StyleProvider::PRIORITY_USER)
         

            window.show_all
        end
        
    end

    # Cette méthode permet de gérer tous les traitements 
    # lors de la validation de l'hypothèse
    # Elle supprime l'ancienne grille et met en place la nouvelle
    def hypotheseValider(newGrid)
        
        @boxJeu.remove(@grid)
        @grid = newGrid
        @grid.expand = true 
        @grid.halign =  Gtk::Align::CENTER
        @grid.valign =  Gtk::Align::CENTER
        @grid.set_row_homogeneous(true)
        @grid.set_column_homogeneous(true)
        if(@grid.grilleFini? )
            self.partiFini
        end 
        @grid.undoRedo.cleanAll()
        @boxJeu.add(@grid)
    end


    # Mis à jour du niveau
    # Dans notre cas on reset le plateau
    def resetPlateau()
        puts "RESET"
        @tempsDebut = Time.now
        $tempsPause = 0
        @temps.set_text("O")
        $timerStop = 0
        $partieStop = 0
       
        @boxJeu.remove(@grid)
        #  Chargement de la grille
        gri = HashiGrid.new(@grid.nomniv,@diff, @grid.lignes, @grid.colonnes)
        @grid = gri
        #creer un fichier de sauvegarde vide
        titre = @grid.nomniv.match(/[^\/]*.txt/)
        f=File.open("./Sauvegarde/#{@grid.diff}/save#{titre}", 'w')
        f.close()

        @aide = Aide.new(@grid)
        gri.colonnes =@grid.colonnes
        gri.lignes = @grid.lignes
        gri.set_column_homogeneous(true)
        gri.set_row_homogeneous(true)
        grid.expand = true 
        gri.chargeGrille()
        gri.chargeVoisins()

        @boxJeu.add(@grid)
        @boxJeu.show_all

    end 
end
