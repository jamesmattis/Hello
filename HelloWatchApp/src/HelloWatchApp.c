#include <pebble.h>

// Window & Text Layer

static Window *window;
static TextLayer *text_layer;
static Layer *base_layer;

// Data buffer

static uint8_t *data_buffer;

// Text Layer Char Buffer

static char text_layer_buffer[8];

// Last Update Time

static time_t lastUpdateTime;

// Start Time

static time_t startTime;

// Display Label Counter

static uint16_t textCounter;

// Pushed Messages Counter

static uint16_t pushedMessagesCounter;

// Received Messages Counter

static uint16_t receivedMessagesCounter;

// Set Messages Counter

static uint16_t setMessagesCounter;

// Data Key Enum

// Animations

static PropertyAnimation *text_layer_animation_up;
static PropertyAnimation *text_layer_animation_down;

enum DataKey
{
    MESSAGE_KEY = 0,       // TUPLE_CSTRING;
    DATA_KEY = 1,          // JUNK DATA;
    SNIFF_KEY = 2          // TUPLE_UINT8
};

static void text_layer_animation_up_completed (Animation *animation, void *data)
{
    // Start Down Animation
    
    animation_schedule((Animation*) text_layer_animation_down);
}

static void text_layer_animation_down_completed (Animation *animation, void *data)
{
    // Start Up Animation
    
    animation_schedule((Animation*) text_layer_animation_up);
}

// Click Config Handler Declarations

static void config_provider(void *context);
static void select_click_handler(ClickRecognizerRef recognizer, void *context);
static void up_click_handler(ClickRecognizerRef recognizer, void *context);
static void down_click_handler(ClickRecognizerRef recognizer, void *context);

// App Focus Handler

static void app_focus_handler(bool in_focus)
{
    // Send App Message Out
    
    DictionaryIterator *iterator;
    
    if (app_message_outbox_begin(&iterator) != APP_MSG_OK)
    {
        return;
    }
    
    if (in_focus)
    {
        if (dict_write_cstring(iterator, MESSAGE_KEY, "IN FOCUS") != DICT_OK)
        {
            return;
        }
    }
    else
    {
        if (dict_write_cstring(iterator, MESSAGE_KEY, "NOT IN FOCUS") != DICT_OK)
        {
            return;
        }
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
    // Received each second
    
    textCounter++;
    
    if (textCounter > 9)
        textCounter = 0;
    
    switch (textCounter) {
        case 0:
            strcpy	(text_layer_buffer, "hello");
            text_layer_set_text(text_layer, "hello");
            break;
        case 1:
            strcpy	(text_layer_buffer, "hallo");
            text_layer_set_text(text_layer, "hallo");
            break;
        case 2:
            strcpy	(text_layer_buffer, "hola");
            text_layer_set_text(text_layer, "hola");
            break;
        case 3:
            strcpy	(text_layer_buffer, "hej");
            text_layer_set_text(text_layer, "hej");
            break;
        case 4:
            strcpy	(text_layer_buffer, "bonjour");
            text_layer_set_text(text_layer, "bonjour");
            break;
        case 5:
            strcpy	(text_layer_buffer, "ciao");
            text_layer_set_text(text_layer, "ciao");
            break;
        case 6:
            strcpy	(text_layer_buffer, "salve");
            text_layer_set_text(text_layer, "salve");
            break;
        case 7:
            strcpy	(text_layer_buffer, "ola");
            text_layer_set_text(text_layer, "ola");
            break;
        case 8:
            strcpy	(text_layer_buffer, "chaoa");
            text_layer_set_text(text_layer, "chaoa");
            break;
        case 9:
            strcpy	(text_layer_buffer, "kaixo");
            text_layer_set_text(text_layer, "kaixo");
            break;
        default:
            break;
    }
    
    setMessagesCounter++;
    
    time_t now = time(NULL);
    
    time_t elapsedTime = now - startTime;
    
    char elapsed_time_text[] = "999999";
    
    snprintf(elapsed_time_text, sizeof(elapsed_time_text), "%ld", elapsedTime);
    
    if (setMessagesCounter % 10000 == 0)
        APP_LOG(APP_LOG_LEVEL_DEBUG, "App Message tick_timer_handler set_text: %s %ld", text_layer_buffer, elapsedTime);
    
    // Log Message Key to App Message System every minute
    
    if (tick_time->tm_sec % 59 == 0)
    {
        pushedMessagesCounter++;

        if (pushedMessagesCounter % 60 == 0)
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
}

// App Message Callbacks

static void out_sent_handler(DictionaryIterator *sent, void *context)
{
    APP_LOG(APP_LOG_LEVEL_DEBUG, "out_sent_handler");
}

static void out_failed_handler(DictionaryIterator *failed, AppMessageResult reason, void *context)
{
    // Log Error
    
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
    
    // Error Handling
    
    if ((reason == APP_MSG_SEND_TIMEOUT || reason == APP_MSG_BUSY) && bluetooth_connection_service_peek())
    {
        // Try Reseanding Message
        
        // Create New Output Iterator
        
        DictionaryIterator *iterator;
        
        if (app_message_outbox_begin(&iterator) != APP_MSG_OK)
        {
            return;
        }
        
        // For Each Tuple in Failed Dictionary Iterator, Read Value, Classify Value, and Write to New Iterator
        
        Tuple *tuple = dict_read_first(failed);
        
        while (tuple)
        {
            switch (tuple->type)
            {
                case TUPLE_BYTE_ARRAY:
                    dict_write_data	(iterator, tuple->key, tuple->value->data, tuple->length);
                    break;
                case TUPLE_CSTRING:
                    dict_write_cstring(iterator, tuple->key, tuple->value->cstring);
                    break;
                case TUPLE_UINT:
                    if (tuple->length == 1)
                    {
                        dict_write_uint8(iterator, tuple->key, tuple->value->uint8);
                    }
                    else if (tuple->length == 2)
                    {
                        dict_write_uint16(iterator, tuple->key, tuple->value->uint16);
                    }
                    else
                    {
                        dict_write_uint32(iterator, tuple->key, tuple->value->uint32);
                    }
                    break;
                case TUPLE_INT:
                    if (tuple->length == 1)
                    {
                        dict_write_int8(iterator, tuple->key, tuple->value->int8);
                    }
                    else if (tuple->length == 2)
                    {
                        dict_write_int16(iterator, tuple->key, tuple->value->int16);
                    }
                    else
                    {
                        dict_write_int32(iterator, tuple->key, tuple->value->int32);
                    }
                    break;
                default:
                    break;
            }
            
            tuple = dict_read_next(failed);
        }
        
        // Resend App Message
        
        app_message_outbox_send();
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
    
    receivedMessagesCounter++;
    
    // Handle Tuples
    
    Tuple *message_tuple = dict_find(received, MESSAGE_KEY);
    Tuple *data_tuple = dict_find(received, DATA_KEY);
    Tuple *sniff_tuple = dict_find(received, SNIFF_KEY);

    if (message_tuple)
    {
        strcpy	(text_layer_buffer, message_tuple->value->cstring);
        text_layer_set_text(text_layer, message_tuple->value->cstring);
        
        if (strcmp (message_tuple->value->cstring, "hello") == 0)
        {
            textCounter = 0;
        }
        if (strcmp (message_tuple->value->cstring, "hallo") == 0)
        {
            textCounter = 1;
        }
        if (strcmp (message_tuple->value->cstring, "hola") == 0)
        {
            textCounter = 2;
        }
        if (strcmp (message_tuple->value->cstring, "hej") == 0)
        {
            textCounter = 3;
        }
        if (strcmp (message_tuple->value->cstring, "bonjour") == 0)
        {
            textCounter = 4;
        }
        if (strcmp (message_tuple->value->cstring, "ciao") == 0)
        {
            textCounter = 5;
        }
        if (strcmp (message_tuple->value->cstring, "salve") == 0)
        {
            textCounter = 6;
        }
        if (strcmp (message_tuple->value->cstring, "ola") == 0)
        {
            textCounter = 7;
        }
        if (strcmp (message_tuple->value->cstring, "chaoa") == 0)
        {
            textCounter = 8;
        }
        if (strcmp (message_tuple->value->cstring, "kaixo") == 0)
        {
            textCounter = 9;
        }
        
        if (receivedMessagesCounter % 10000 == 0)
            APP_LOG(APP_LOG_LEVEL_DEBUG, "[%s] App Message in_received_handler ELAPSED TIME: %ld message: %s", error_time_text, elapsedTime, message_tuple->value->cstring);
    }
    else
    {
        APP_LOG(APP_LOG_LEVEL_DEBUG, "[%s] App Message in_received_handler ELAPSED TIME: %ld NO MESSAGE TUPLE", error_time_text, elapsedTime);
    }
    
    if (data_tuple)
    {
        if (data_buffer != NULL)
        {
            free(data_buffer);
        }
        
        data_buffer = malloc(data_tuple->length);
        
        memcpy(data_buffer, data_tuple->value->data, data_tuple->length);
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
    
    text_layer_animation_up = property_animation_create_layer_frame(text_layer_get_layer(text_layer), &GRect(0, 67, 144, 34), &GRect(0, -34, 144, 34));
    animation_set_duration((Animation*) text_layer_animation_up, 5000);
    animation_set_curve((Animation*) text_layer_animation_up, AnimationCurveEaseInOut);
    animation_set_handlers((Animation*) text_layer_animation_up, (AnimationHandlers) {.stopped = (AnimationStoppedHandler) text_layer_animation_up_completed,}, NULL);
    
    text_layer_animation_down = property_animation_create_layer_frame(text_layer_get_layer(text_layer), &GRect(0,-34, 144, 34), &GRect(0, 67, 144, 34));
    animation_set_duration((Animation*) text_layer_animation_down, 5000);
    animation_set_curve((Animation*) text_layer_animation_down, AnimationCurveEaseInOut);
    animation_set_handlers((Animation*) text_layer_animation_down, (AnimationHandlers) {.stopped = (AnimationStoppedHandler) text_layer_animation_down_completed,}, NULL);
}

static void window_load(Window *window)
{
    init_text_layers();
}

static void window_unload(Window *window)
{
    property_animation_destroy(text_layer_animation_up);
    property_animation_destroy(text_layer_animation_down);
    
    Layer *window_layer = window_get_root_layer(window);
    layer_remove_child_layers(window_layer);

    layer_remove_child_layers(base_layer);

    text_layer_destroy(text_layer);
    
    layer_destroy(base_layer);
}


static void window_appear(Window *window)
{
    // Start Animation
    
    animation_schedule((Animation*) text_layer_animation_up);
}

// Init Variables Method

static void init_variables(void)
{
    // Init char pointers
	
	strcpy (text_layer_buffer, "hello");
    
    lastUpdateTime = time(NULL);
    
    startTime = time(NULL);
    
    textCounter = 0;
    
    pushedMessagesCounter = 0;
    receivedMessagesCounter = 0;
    setMessagesCounter = 0;
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
        .appear = window_appear,
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
    
    tick_timer_service_subscribe(SECOND_UNIT, tick_timer_handler);
}

static void init_focus_service(void)
{
    // Subscribe to the app focus service
    
    app_focus_service_subscribe(app_focus_handler);
}

void handle_init(void)
{
    // Init
    
    init_variables();
    init_window();
    init_app_messages();
    init_focus_service();
    init_tick_service();
    
    // Send Launch Message
    
    send_launch_message();
}

void handle_deinit(void)
{
    // Send Exit Message
    
    send_exit_message();
    
    // De-init
    
    app_focus_service_unsubscribe();
    app_message_deregister_callbacks();
    tick_timer_service_unsubscribe();
    window_destroy(window);
    
    if (data_buffer != NULL)
    {
        free(data_buffer);
    }
}

int main(void)
{
    handle_init();
    app_event_loop();
    handle_deinit();
}
