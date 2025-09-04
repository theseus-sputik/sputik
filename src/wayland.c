#include <wayland-client.h>


struct wl_display* c_init_wayland(void) {
	struct wl_display *display = wl_display_connect(NULL);
	if (!display) return NULL;
	// initialize compositor, xdg_shell
	return display;
}

void c_create_surface(struct wl_display *display){
	// create pt and flash

}
