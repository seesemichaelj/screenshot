/*
* Copyright (c) 2014-2016 Fabio Zaramella <ffabio.96.x@gmail.com>
*               2017 elementary LLC. (https://elementary.io)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU Lesser General Public
* License version 3 as published by the Free Software Foundation.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* Lesser General Public License for more details.
*
* You should have received a copy of the GNU Lesser General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*/

namespace Screenshot.Widgets {
    public class SelectionArea : Granite.Widgets.CompositedWindow {
        public signal void captured ();
        public signal void cancelled ();

        private Gdk.Point start_point;

        private bool dragging = false;

        private enum CursorLocation {
            TOP_LEFT,
            TOP_RIGHT,
            BOTTOM_LEFT,
            BOTTOM_RIGHT
        }
        private CursorLocation cursor_location;

        construct {
            type = Gtk.WindowType.POPUP;
        }

        public SelectionArea () {
            stick ();
            set_resizable (true);
            set_deletable (false);
            set_skip_taskbar_hint (true);
            set_skip_pager_hint (true);
            set_keep_above (true);

            var screen = get_screen ();
            set_default_size (screen.get_width (), screen.get_height ());
        }

        public override bool button_press_event (Gdk.EventButton e) {
            if (dragging || e.button != 1) {
                return true;
            }

            dragging = true;

            start_point.x = (int)e.x_root;
            start_point.y = (int)e.y_root;

            return true;            
        }

        public override bool button_release_event (Gdk.EventButton e) {
            if (!dragging || e.button != 1) {
                return true;
            }

            dragging = false;
            captured ();

            return true;            
        }

        public override bool motion_notify_event (Gdk.EventMotion e) {
            if (!dragging) {
                return true;
            }

            int x = start_point.x;
            int y = start_point.y;

            int width = (x - (int)e.x_root).abs ();
            int height = (y - (int)e.y_root).abs ();
            if (width < 1 || height < 1) {
                return true;
            }

            x = int.min (x, (int)e.x_root);
            y = int.min (y, (int)e.y_root);

            //width += 50;
            //height -= 50;
            if (x == (int)e.x_root && y == (int)e.y_root) {
                cursor_location = CursorLocation.TOP_LEFT;
                /*x -= 50;
                y -= 50;
                width += 50;
                height += 50;*/
                stdout.printf("top left\n");
            }
            else if (x == start_point.x && y == (int)e.y_root) {
                cursor_location = CursorLocation.TOP_RIGHT;
                //width += 50;
                //y -= 50;
                //height += 50;
                stdout.printf("top right\n");
            }
            else if (x == (int) e.x_root && y == start_point.y) {
                cursor_location = CursorLocation.BOTTOM_LEFT;
                //x -= 50;
                //y += 50;
                //width += 50;

                stdout.printf("bottom left\n");
            }
            else if (x == start_point.x && y == start_point.y) {
                cursor_location = CursorLocation.BOTTOM_RIGHT;
                //width += 50;
                //height += 50;
                stdout.printf("bottom right\n");
            }
            x -= 50;
            y -= 50;
            width += 100;
            height += 100;

            move (x, y);
            resize (width, height);

            return true;            
        }

        public override bool key_press_event (Gdk.EventKey e) {
            if (e.keyval == Gdk.Key.Escape) {
                cancelled ();
            }

            return true;            
        }

        public override void show_all () {
            base.show_all ();
            var manager = Gdk.Display.get_default ().get_device_manager ();
            var pointer = manager.get_client_pointer ();
            var keyboard = pointer.get_associated_device ();
            var window = get_window ();

            var status = pointer.grab (window,
                        Gdk.GrabOwnership.NONE,
                        false,
                        Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.BUTTON_RELEASE_MASK | Gdk.EventMask.POINTER_MOTION_MASK,
                        new Gdk.Cursor.for_display (window.get_display (), Gdk.CursorType.CROSSHAIR),
                        Gtk.get_current_event_time ());

            if (status != Gdk.GrabStatus.SUCCESS) {
                pointer.ungrab (Gtk.get_current_event_time ());
            }

            if (keyboard != null) {
                status = keyboard.grab (window,
                        Gdk.GrabOwnership.NONE,
                        false,
                        Gdk.EventMask.KEY_PRESS_MASK,
                        null,
                        Gtk.get_current_event_time ());

                if (status != Gdk.GrabStatus.SUCCESS) {
                    keyboard.ungrab (Gtk.get_current_event_time ());
                }                
            }
        }

        public new void close () {
            get_window ().set_cursor (null);
            base.close ();
        }

        public override bool draw (Cairo.Context ctx) {
            if (!dragging) {
                return true;
            }

            int startx = 50;
            int starty = 50;
            int w = get_allocated_width () - 100;
            int h = get_allocated_height () - 100;

            ctx.rectangle (startx, starty, w, h);
            ctx.set_source_rgba (0.1, 0.1, 0.1, 0.2);
            ctx.fill ();

            ctx.rectangle (startx, starty, w, h);
            ctx.set_source_rgb (0.7, 0.7, 0.7);
            ctx.set_line_width (1.0);
            ctx.stroke ();

            var manager = Gdk.Display.get_default ().get_device_manager ();
            var pointer = manager.get_client_pointer ();
            Gdk.Screen screen;
            int cursorx;
            int cursory;
            int winx;
            int winy;
            pointer.get_position (out screen, out cursorx, out cursory);
            get_window().get_position(out winx, out winy);
            cursorx -= winx;
            cursory -= winy;

            int font_size = 10;

            ctx.set_source_rgba(0.1, 0.1, 0.1, 0.8);
            ctx.select_font_face("Purisa", Cairo.FontSlant.NORMAL, Cairo.FontWeight.BOLD);
            ctx.set_font_size (font_size);

            Cairo.TextExtents extents;
            ctx.text_extents(w.to_string(), out extents);
            switch (cursor_location) {
                case CursorLocation.TOP_LEFT: {
                    ctx.move_to (cursorx - extents.width, cursory - font_size * 1 - 5);
                    break;
                }
                case CursorLocation.TOP_RIGHT: {
                    ctx.move_to (cursorx - extents.width, cursory - font_size * 2);
                    break;
                }
                case CursorLocation.BOTTOM_LEFT: {
                    ctx.move_to (cursorx - extents.width, cursory - font_size * 2);
                    break;
                }
                case CursorLocation.BOTTOM_RIGHT: {
                    ctx.move_to (cursorx - extents.width, cursory - font_size * 2);
                    break;
                }
            }
            ctx.show_text(w.to_string());

            ctx.text_extents(h.to_string(), out extents);
            switch (cursor_location) {
                case CursorLocation.TOP_LEFT: {
                    ctx.move_to (cursorx - extents.width, cursory - font_size * 0 - 5);
                    break;
                }
                case CursorLocation.TOP_RIGHT: {
                    ctx.move_to (cursorx - extents.width, cursory - font_size * 1);
                    break;
                }
                case CursorLocation.BOTTOM_LEFT: {
                    ctx.move_to (cursorx - extents.width, cursory - font_size * 1);
                    break;
                }
                case CursorLocation.BOTTOM_RIGHT: {
                    ctx.move_to (cursorx - extents.width, cursory - font_size * 1);
                    break;
                }
            }
            ctx.show_text(h.to_string());

            return base.draw (ctx);
        }
    }
}
