/*
* Copyright (C) 2017-2022 Lains
*
* This program is free software; you can redistribute it &&/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*/
[GtkTemplate (ui = "/io/github/lainsce/Notejot/notegridrowcontent.ui")]
public class Notejot.NoteGridRowContent : He.Bin {
    [GtkChild]
    private unowned Gtk.Image pin;
    [GtkChild]
    private unowned Gtk.Box row_box;
    [GtkChild]
    private unowned Gtk.TextView textbox;

    private Binding? pinned_binding;
    private Binding? color_binding;
    private Gtk.CssProvider provider = new Gtk.CssProvider();

    private string? _color;
    public string? color {
        get { return _color; }
        set {
            if (value == _color)
                return;

            _color = value;
        }
    }

    private Note? _note;
    public Note? note {
        get { return _note; }
        set {
            if (value == _note)
                return;

            pinned_binding?.unbind ();
            color_binding?.unbind ();

            _note = value;

            pinned_binding = _note?.bind_property (
                "pinned", pin, "visible", SYNC_CREATE|BIDIRECTIONAL);
            color_binding = _note?.bind_property (
                "color", this, "color", SYNC_CREATE|BIDIRECTIONAL);

            provider.load_from_data ((uint8[]) "@define-color note_color %s;".printf(_note.color));
            ((MainWindow)MiscUtils.find_ancestor_of_type<MainWindow>(this)).view_model.update_note_color (_note, _color);
            row_box.get_style_context().add_provider(provider, 1);
        }
    }

    public NoteGridRowContent (Note note) {
        Object(
            note: note
        );
    }

    construct {
        row_box.get_style_context().add_provider(provider, 1);
        textbox.remove_css_class ("view");
        textbox.add_css_class ("nb");
    }

    ~NoteGridRowContent () {
        while (this.get_first_child () != null) {
            var c = this.get_first_child ();
            c.unparent ();
        }
        this.unparent ();
    }

    [GtkCallback]
    string get_text_line () {
        var res = sync_texts (note.text);
        return res;
    }

    public string sync_texts (string text) {
        string res = "";
        try {
            var reg = new Regex("""(?m)(?<sentence>[^.!?\s][^.!?]*(?:[.!?](?!['"]?\s|$)[^.!?]*)*[.!?]?['"]?(?=\s|$))$""");
            GLib.MatchInfo match;

            if (log != null) {
                if (reg.match (text, 0, out match)) {
                    res = "%s".printf(match.fetch_named ("sentence"));
                }
            }
        } catch (GLib.RegexError re) {
            warning ("%s".printf(re.message));
        }

        return res;
    }
}
