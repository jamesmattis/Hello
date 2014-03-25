#include <pebble.h>

// Window & Text Layer

static Window *window;
static TextLayer *text_layer;
static Layer *base_layer;

// Text Layer Char Buffer

static char text_layer_buffer[8];

// Last Update Time

static time_t lastUpdateTime;

// Start Time

static time_t startTime;

// Data Key Enum

enum DataKey
{
    MESSAGE_KEY = 0,       // TUPLE_CSTRING;
    DATA_KEY = 1,          // JUNK DATA;
    SNIFF_KEY = 2          // TUPLE_UINT8
};

// Click Config Handler Declarations

static void config_provider(void *context);
static void select_click_handler(ClickRecognizerRef recognizer, void *context);
static void up_click_handler(ClickRecognizerRef recognizer, void *context);
static void down_click_handler(ClickRecognizerRef recognizer, void *context);

// App Focus Handler

static void app_focus_handler(bool in_focus)
{
    char message_text[12];
    
    if (in_focus)
    {
        strcpy	(message_text, "IN FOCUS");
    }
    else
    {
        strcpy	(message_text, "NOT IN FOCUS");
    }
    
    // Send App Message Out
    
    DictionaryIterator *iterator;
    
    if (app_message_outbox_begin(&iterator) != APP_MSG_OK)
    {
        return;
    }
    
    if (dict_write_cstring(iterator, MESSAGE_KEY, message_text) != DICT_OK)
    {
        return;
    }
    
    app_message_outbox_send();
}

static void select_click_handler(ClickRecognizerRef recognizer, void *context)
{
    char message_text[] = "Select Button Press";
    
    // Send App Message Out
    
    DictionaryIterator *iterator;
    
    if (app_message_outbox_begin(&iterator) != APP_MSG_OK)
    {
        return;
    }
    
    if (dict_write_cstring(iterator, MESSAGE_KEY, message_text) != DICT_OK)
    {
        return;
    }
    
    app_message_outbox_send();
}

static void up_click_handler(ClickRecognizerRef recognizer, void *context)
{
    char message_text[] = "Up Button Press";
    
    // Send App Message Out
    
    DictionaryIterator *iterator;
    
    if (app_message_outbox_begin(&iterator) != APP_MSG_OK)
    {
        return;
    }
    
    if (dict_write_cstring(iterator, MESSAGE_KEY, message_text) != DICT_OK)
    {
        return;
    }
    
    app_message_outbox_send();
}

static void down_click_handler(ClickRecognizerRef recognizer, void *context)
{
    char message_text[] = "Down Button Press";
    
    // Send App Message Out
    
    DictionaryIterator *iterator;
    
    if (app_message_outbox_begin(&iterator) != APP_MSG_OK)
    {
        return;
    }
    
    if (dict_write_cstring(iterator, MESSAGE_KEY, message_text) != DICT_OK)
    {
        return;
    }
    
    app_message_outbox_send();
}

//#pragma mark - CLICK CONFIG PROVIDERS

static void config_provider(void *context)
{
    window_single_click_subscribe(BUTTON_ID_SELECT, select_click_handler);
    window_single_click_subscribe(BUTTON_ID_UP, up_click_handler);
    window_single_click_subscribe(BUTTON_ID_DOWN, down_click_handler);
}

// Send Exit Message

static void send_exit_message(void)
{
    char message_text[] = "Good Bye!";
    
    // Send App Message Out
    
    DictionaryIterator *iterator;
    
    if (app_message_outbox_begin(&iterator) != APP_MSG_OK)
    {
        return;
    }
    
    if (dict_write_cstring(iterator, MESSAGE_KEY, message_text) != DICT_OK)
    {
        return;
    }
    
    app_message_outbox_send();
}

// Send Launch Message

static void send_launch_message(void)
{
    char message_text[] = "HELLO!";
    
    // Send App Message Out
    
    DictionaryIterator *iterator;
    
    if (app_message_outbox_begin(&iterator) != APP_MSG_OK)
    {
        return;
    }
    
    if (dict_write_cstring(iterator, MESSAGE_KEY, message_text) != DICT_OK)
    {
        return;
    }
    
    app_message_outbox_send();
}

// Tick Timer Handler

static void tick_timer_handler(struct tm *tick_time, TimeUnits units_changed)
{
    // Received each minute
    
    time_t now = time(NULL);
    
    time_t elapsedTime = now - startTime;
    
    char elapsed_time_text[] = "999999";
    
    snprintf(elapsed_time_text, sizeof(elapsed_time_text), "%ld", elapsedTime);
    
    APP_LOG(APP_LOG_LEVEL_DEBUG, "App Message tick_timer_handler %ld", elapsedTime);
    
    // Send App Message Out
    
    DictionaryIterator *iterator;
    
    if (app_message_outbox_begin(&iterator) != APP_MSG_OK)
    {
        return;
    }
    
    if (dict_write_cstring(iterator, MESSAGE_KEY, elapsed_time_text) != DICT_OK)
    {
        return;
    }
    
    app_message_outbox_send();
}

// App Message Callbacks

static void out_sent_handler(DictionaryIterator *sent, void *context)
{
    APP_LOG(APP_LOG_LEVEL_DEBUG, "out_sent_handler");
}

static void out_failed_handler(DictionaryIterator *failed, AppMessageResult reason, void *context)
{
    time_t now = time(NULL);
    struct tm *clock_time = localtime(&now);
    
    char error_time_text[] = "00:00:00";
    
    strftime(error_time_text, sizeof(error_time_text), "%T", clock_time);
    
    if (reason == APP_MSG_OK)
    {
        APP_LOG(APP_LOG_LEVEL_DEBUG, "[%s] App Message out_failed_handler: APP_MSG_OK", error_time_text);
    }
    else if (reason == APP_MSG_SEND_TIMEOUT)
    {
        APP_LOG(APP_LOG_LEVEL_DEBUG, "[%s] App Message out_failed_handler: APP_MSG_SEND_TIMEOUT", error_time_text);
    }
    else if (reason == APP_MSG_SEND_REJECTED)
    {
        APP_LOG(APP_LOG_LEVEL_DEBUG, "[%s] App Message out_failed_handler: APP_MSG_SEND_REJECTED", error_time_text);
    }
    else if (reason == APP_MSG_NOT_CONNECTED)
    {
        APP_LOG(APP_LOG_LEVEL_DEBUG, "[%s] App Message out_failed_handler: APP_MSG_NOT_CONNECTED", error_time_text);
    }
    else if (reason == APP_MSG_APP_NOT_RUNNING)
    {
        APP_LOG(APP_LOG_LEVEL_DEBUG, "[%s] App Message out_failed_handler: APP_MSG_APP_NOT_RUNNING", error_time_text);
    }
    else if (reason == APP_MSG_INVALID_ARGS)
    {
        APP_LOG(APP_LOG_LEVEL_DEBUG, "[%s] App Message out_failed_handler: APP_MSG_INVALID_ARGS", error_time_text);
    }
    else if (reason == APP_MSG_BUSY)
    {
        APP_LOG(APP_LOG_LEVEL_DEBUG, "[%s] App Message out_failed_handler: APP_MSG_BUSY", error_time_text);
    }
    else if (reason == APP_MSG_BUFFER_OVERFLOW)
    {
        APP_LOG(APP_LOG_LEVEL_DEBUG, "[%s] App Message out_failed_handler: APP_MSG_BUFFER_OVERFLOW", error_time_text);
    }
    else if (reason == APP_MSG_ALREADY_RELEASED)
    {
        APP_LOG(APP_LOG_LEVEL_DEBUG, "[%s] App Message out_failed_handler: APP_MSG_ALREADY_RELEASED", error_time_text);
    }
    else if (reason == APP_MSG_CALLBACK_ALREADY_REGISTERED)
    {
        APP_LOG(APP_LOG_LEVEL_DEBUG, "[%s] App Message out_failed_handler: APP_MSG_CALLBACK_ALREADY_REGISTERED", error_time_text);
    }
    else if (reason == APP_MSG_CALLBACK_NOT_REGISTERED)
    {
        APP_LOG(APP_LOG_LEVEL_DEBUG, "[%s] App Message out_failed_handler: APP_MSG_CALLBACK_NOT_REGISTERED", error_time_text);
    }
}

static void in_received_handler(DictionaryIterator *received, void *context)
{
    // Log Time & Elapsed Time
    
    time_t now = time(NULL);
    
    time_t elapsedTime = now - lastUpdateTime;
    
    lastUpdateTime = time(NULL);
    
    struct tm *clock_time = localtime(&now);
    
    char error_time_text[] = "00:00:00";
    
    strftime(error_time_text, sizeof(error_time_text), "%T", clock_time);
    
    // Handle Tuples
    
    Tuple *message_tuple = dict_find(received, MESSAGE_KEY);
    
    Tuple *sniff_tuple = dict_find(received, SNIFF_KEY);

    if (message_tuple)
    {
        strcpy	(text_layer_buffer, message_tuple->value->cstring);
        text_layer_set_text(text_layer, message_tuple->value->cstring);
        
        APP_LOG(APP_LOG_LEVEL_DEBUG, "[%s] App Message in_received_handler ELAPSED TIME: %ld message: %s", error_time_text, elapsedTime, message_tuple->value->cstring);
    }
    else
    {
        APP_LOG(APP_LOG_LEVEL_DEBUG, "[%s] App Message in_received_handler ELAPSED TIME: %ld NO MESSAGE TUPLE", error_time_text, elapsedTime);
    }
    
    if (sniff_tuple)
    {
        APP_LOG(APP_LOG_LEVEL_DEBUG, "[%s] App Message in_received_handler ELAPSED TIME: %ld SNIFF_KEY RECEIVED", error_time_text, elapsedTime);
        
        
        if (sniff_tuple->value->uint8)
        {
            // Set Reduced Sniff Interval for Faster Response Time
            
            app_comm_set_sniff_interval(SNIFF_INTERVAL_REDUCED);
            
            char message_text[] = "Set SNIFF_INTERVAL_REDUCED";
            
            // Send App Message Out
            
            DictionaryIterator *iterator;
            
            if (app_message_outbox_begin(&iterator) != APP_MSG_OK)
            {
                return;
            }
            
            if (dict_write_cstring(iterator, MESSAGE_KEY, message_text) != DICT_OK)
            {
                return;
            }
            
            app_message_outbox_send();
        }
        else
        {
            // Set Normal Sniff Interval
            
            app_comm_set_sniff_interval(SNIFF_INTERVAL_NORMAL);
            
            char message_text[] = "Set SNIFF_INTERVAL_NORMAL";
            
            // Send App Message Out
            
            DictionaryIterator *iterator;
            
            if (app_message_outbox_begin(&iterator) != APP_MSG_OK)
            {
                return;
            }
            
            if (dict_write_cstring(iterator, MESSAGE_KEY, message_text) != DICT_OK)
            {
                return;
            }
            
            app_message_outbox_send();
        }
    }
}

static void in_dropped_handler(AppMessageResult reason, void *context)
{
    time_t now = time(NULL);
    struct tm *clock_time = localtime(&now);
    
    char error_time_text[] = "00:00:00";
    
    strftime(error_time_text, sizeof(error_time_text), "%T", clock_time);
    
    if (reason == APP_MSG_OK)
    {
        APP_LOG(APP_LOG_LEVEL_DEBUG, "[%s] App Message in_dropped_handler: APP_MSG_OK", error_time_text);
    }
    else if (reason == APP_MSG_SEND_TIMEOUT)
    {
        APP_LOG(APP_LOG_LEVEL_DEBUG, "[%s] App Message in_dropped_handler: APP_MSG_SEND_TIMEOUT", error_time_text);
    }
    else if (reason == APP_MSG_SEND_REJECTED)
    {
        APP_LOG(APP_LOG_LEVEL_DEBUG, "[%s] App Message in_dropped_handler: APP_MSG_SEND_REJECTED", error_time_text);
    }
    else if (reason == APP_MSG_NOT_CONNECTED)
    {
        APP_LOG(APP_LOG_LEVEL_DEBUG, "[%s] App Message in_dropped_handler: APP_MSG_NOT_CONNECTED", error_time_text);
    }
    else if (reason == APP_MSG_APP_NOT_RUNNING)
    {
        APP_LOG(APP_LOG_LEVEL_DEBUG, "[%s] App Message in_dropped_handler: APP_MSG_APP_NOT_RUNNING", error_time_text);
    }
    else if (reason == APP_MSG_INVALID_ARGS)
    {
        APP_LOG(APP_LOG_LEVEL_DEBUG, "[%s] App Message in_dropped_handler: APP_MSG_INVALID_ARGS", error_time_text);
    }
    else if (reason == APP_MSG_BUSY)
    {
        APP_LOG(APP_LOG_LEVEL_DEBUG, "[%s] App Message in_dropped_handler: APP_MSG_BUSY", error_time_text);
    }
    else if (reason == APP_MSG_BUFFER_OVERFLOW)
    {
        APP_LOG(APP_LOG_LEVEL_DEBUG, "[%s] App Message in_dropped_handler: APP_MSG_BUFFER_OVERFLOW", error_time_text);
    }
    else if (reason == APP_MSG_ALREADY_RELEASED)
    {
        APP_LOG(APP_LOG_LEVEL_DEBUG, "[%s] App Message in_dropped_handler: APP_MSG_ALREADY_RELEASED", error_time_text);
    }
    else if (reason == APP_MSG_CALLBACK_ALREADY_REGISTERED)
    {
        APP_LOG(APP_LOG_LEVEL_DEBUG, "[%s] App Message in_dropped_handler: APP_MSG_CALLBACK_ALREADY_REGISTERED", error_time_text);
    }
    else if (reason == APP_MSG_CALLBACK_NOT_REGISTERED)
    {
        APP_LOG(APP_LOG_LEVEL_DEBUG, "[%s] App Message in_dropped_handler: APP_MSG_CALLBACK_NOT_REGISTERED", error_time_text);
    }
}

// Init Text Layers Method

static void init_text_layers(void)
{
    // text_layer = text_layer_create(GRect(x,  y, width, height));
    
    // Time Text Layer and Label
    
    base_layer = layer_create (GRect(0, 0, 144, 168));
    
    text_layer = text_layer_create(GRect(0, 67, 144, 34));
    text_layer_set_font(text_layer, fonts_get_system_font(FONT_KEY_GOTHIC_28_BOLD));
    text_layer_set_text_alignment(text_layer, GTextAlignmentCenter);
    text_layer_set_background_color(text_layer, GColorClear);
    text_layer_set_text_color(text_layer, GColorWhite);
    
    // Add Layers to Root Window
    
    layer_add_child(base_layer, text_layer_get_layer(text_layer));
    
    layer_add_child(window_get_root_layer(window), base_layer);
    
    // Set Initial Text Layer Text
    
    text_layer_set_text(text_layer, "hello");
    
    // Set Window Click Config Provider
    
    window_set_click_config_provider(window, (ClickConfigProvider) config_provider);
}

static void window_load(Window *window)
{
    init_text_layers();
}

static void window_unload(Window *window)
{
    text_layer_destroy(text_layer);
    
    layer_destroy(base_layer);
    
    tick_timer_service_unsubscribe();
}

// Init Variables Method

static void init_variables(void)
{
    // Init char pointers
	
	strcpy	(text_layer_buffer, "hello");
    
    lastUpdateTime = time(NULL);
    
    startTime = time(NULL);
}

// Init Root Window Method

static void init_window(void)
{
    // Init Main Window
    
    window = window_create();
    window_set_background_color(window, GColorBlack);
    window_set_fullscreen(window, true);
    
    window_set_window_handlers(window, (WindowHandlers) {
        .load = window_load,
        .unload = window_unload
    });
    
    window_stack_push(window, true /* Animated */);
}

static void init_app_messages(void)
{
    // Set Up App Messages - Max Input Size is 124
    
    app_message_open(124, 124);
    
    // Register message handlers
    
    app_message_register_inbox_received(in_received_handler);
    app_message_register_inbox_dropped(in_dropped_handler);
    app_message_register_outbox_failed(out_failed_handler);
    app_message_register_outbox_sent(out_sent_handler);
}

static void init_tick_service(void)
{
    // Subscribe to tick timer service
    
    tick_timer_service_subscribe(MINUTE_UNIT, tick_timer_handler);
}

static void init_focus_service(void)
{
    // Subscribe to the app focus service
    
    app_focus_service_subscribe(app_focus_handler);
}

void handle_init(void)
{
    // Init
    
    init_app_messages();
    init_focus_service();
    init_window();
    init_variables();
    init_tick_service();
    
    // Send Launch Message
    
    send_launch_message();
}

void handle_deinit(void)
{
    // Send Exit Message
    
    send_exit_message();
    
    // De-init
    
    window_destroy(window);
    
    app_focus_service_unsubscribe();
}

int main(void)
{
    handle_init();
    app_event_loop();
    handle_deinit();
}
