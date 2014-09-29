<?php

function printconnect_init() {
  global $language;
  global $conf;
  global $browscap;
  global $base_url;
  
  $uriRequest = split('/', request_uri());
  unset($uriRequest[0]);
  $urlPermant = '';
  $redirectPermanant = FALSE;
  $arrayBaseurl = split('[/.-]', $base_url); 
  $uriExtention = $arrayBaseurl[sizeof($arrayBaseurl)-1];
  $arrayExtention = array(
                        'be' => array('nlnl' => 'benl',
                                      'frfr' => 'befr',
                                      'lufr' => 'befr',
                                        ),
                        'fr' => 'frfr',
                        'nl' => 'nlnl',
                        'lu' => 'lufr',
                            );
  if(isset($arrayExtention["$uriExtention"]) && is_array($arrayExtention["$uriExtention"])){
    if(array_key_exists($uriRequest[1], $arrayExtention["$uriExtention"]) == TRUE OR !is_array($arrayExtention["$uriExtention"])){
        if(is_array($arrayExtention["$uriExtention"])){
            $uriLang = $arrayExtention["$uriExtention"]["$uriRequest[1]"];
            unset($uriRequest[1]);
            $urlPermant = $base_url . '/' .$uriLang . '/' .implode('/',$uriRequest);
            $redirectPermanant = TRUE;
        } else {
            if($arrayExtention["$uriExtention"] != $uriRequest[1]){
                $uriLang = $arrayExtention["$uriExtention"];
                unset($uriRequest[1]);
                $urlPermant = $base_url . '/' .$uriLang . '/' .implode('/',$uriRequest);
                $redirectPermanant = TRUE;
            }
        }

    }
  }
//session_start();
    if($redirectPermanant == FALSE){
    $browscap = TRUE;
    if (module_exists('browscap')) {
      $info = browscap_get_browser();

      $browser = $info['browser'];
      $version = $info['majorver'];

      switch ($browser) {
        case 'IE':
          if ($version < 8) {
            $browscap = FALSE;
          }
          break;
        case 'Firefox':
          if ($version < 16) {
            $browscap = FALSE;
          }
          break;
        case 'Chrome':
          if ($version < 23) {
            $browscap = FALSE;
          }
          break;
        case 'Safari':
          if ($version < 5) {
            $browscap = FALSE;
          }
      }
    }

    printconnect_ensureinitialized();
    if (!drupal_is_cli()) {
      $language_list = language_list();
      $path = $_GET['q'];

      $newLanguage = FALSE;

      if (isset($language->provider) && $language->provider == 'language-default') {
        //default language
        if (isset($_SESSION['pc_language'])
                && $_SESSION['pc_language'] != $language->language
                && isset($language_list[$_SESSION['pc_language']])
        ) {
          //use session language
          $newLanguage = $language_list[$_SESSION['pc_language']];
        } else {
          //use first configured language
          if (isset($conf['languages']) && isset($conf['languages'][0]) && isset($language_list[$conf['languages'][0]])) {
            $newLanguage = $language_list[$conf['languages'][0]];
          }
        }
      }

      if ($newLanguage && ($newLanguage->language != $language->language)) {
        $query = drupal_get_query_parameters();
  //   unset($query['q']);
        if (drupal_is_front_page()) {
          drupal_goto('<front>', array('language' => $newLanguage, 'query' => $query), 301);
        } else {
          drupal_goto($path, array('language' => $newLanguage, 'query' => $query), 301);
        }
      }


      $locale = $language->language;
      $locale = strtoupper(str_replace('-', '_', $locale));

      $pclanguages = \printconnect\Languages\Factory::GetAll();
      $pclanguages->EnsureLoaded();
      $pclanguageFound = FALSE;
      foreach ($pclanguages->items as $pclanguage) {
        if (preg_match('/^' . preg_quote($locale) . "/", strtoupper($pclanguage->locale))) {
          $language->id = $pclanguage->id;
          $language->code = $pclanguage->internalCode;
          $language->locale = $pclanguage->locale;
          $pclanguageFound = TRUE;
          break;
        }
      }

      if (!$pclanguageFound) {
        //take the first one
        foreach ($pclanguages->items as $pclanguage) {
          $language->id = $pclanguage->id;
          $language->code = $pclanguage->internalCode;
          $language->locale = $pclanguage->locale;
          break;
        }
      }

      //   setcookie('pc_language', $language->language, time() + 60 * 60 * 24 * 365, '/');
      $_SESSION['pc_language'] = $language->language;
    }

  //  
  //  drupal_add_js('http://cdnjs.cloudflare.com/ajax/libs/fancybox/2.1.4/jquery.fancybox.pack.js');
  //  drupal_add_css('http://cdnjs.cloudflare.com/ajax/libs/fancybox/2.1.4/jquery.fancybox.css', array('type' => 'external'));

    $shop = \printconnect\Shop\Configuration\Factory::Current();
      \printconnect\Shop\Configuration\Factory::LoadConfiguration($shop);

      if(!isset($_SESSION['shop_vat'])){
      $_SESSION['shop_vat']= $shop->defaultvat;
      }
    }else{
        drupal_goto($urlPermant,array(),301);
    }  
}

function printconnect_cron() {
    define('DRUPAL_ROOT', getcwd());
    include_once('../../../includes/bootstrap.inc');
    drupal_bootstrap(DRUPAL_BOOTSTRAP_FULL);
    registry_rebuild();
    system_rebuild_theme_data();
    drupal_theme_rebuild();
    entity_info_cache_clear();
    node_types_rebuild();
    menu_rebuild();
    $core = array('cache', 'cache_path', 'cache_filter', 'cache_bootstrap', 'cache_page');
    $cache_tables = array_merge(module_invoke_all('flush_caches'), $core);
    foreach ($cache_tables as $table) {
        cache_clear_all('*', $table, TRUE);
    }
    _system_update_bootstrap_status();
    drupal_set_message(t('Cron for menu_rebuild_needed corn has been run accusedly.'));
}

function printconnect_ensureinitialized() {
  global $pcDal;

  static $init = FALSE;

  if ($init == FALSE) {

    module_invoke_all('printconnectinit');

    spl_autoload_register("_printconnect_autoload", FALSE);

    $dals = module_invoke_all('dal_info');

    if (count($dals)) {
      $callback = $dals[variable_get('pc_dal', 'restdal')]['#callback'];
      if ($callback) {
        $pcDal = $callback();
      }
    }
    $init = TRUE;
  }
}

function _printconnect_autoload($className) {
  static $cache = null;
  if (!$cache) {
    $cache = cache_get('_printconnect_autoload', 'cache');
    if (!$cache) {
      $cache = array();
    } else {
      $cache = $cache->data;
    }
  }
  $path = str_replace('\\', '/', $className) . '.php';
  if (!array_key_exists($className, $cache)) {
    foreach (module_list(FALSE, TRUE) as $module) {
      $classPath = drupal_get_path('module', $module) . '/classes/' . $path;
      if (file_exists($classPath)) {
        $cache[$className] = $classPath;
        cache_set('_printconnect_autoload', $cache, 'cache');
        break;
      }
    }
    if (!isset($cache[$className])) {
      $cache[$className] = FALSE;
    }
  }

  if ($cache[$className]) {
    include_once(DRUPAL_ROOT . '/' . $cache[$className]);
  }
}

function printconnect_menu() {
  /*
    $items['admin/printconnect'] = array(
    'title' => 'printconnect Settings',
    'page callback' => 'drupal_get_form',
    'page arguments' => array('_printconnect_settings'),
    'access arguments' => array('administer site configuration'),
    );

    $items['admin/printconnect/overview'] = array(
    'title' => 'Overview',
    'type' => MENU_DEFAULT_LOCAL_TASK,
    );

   */
  $items['js/country/%'] = array(
      'page callback' => '_printconnect_js_callback',
      'page arguments' => array(1, 2),
      'access arguments' => array('access content'),
      'type' => MENU_CALLBACK,
  );

  return $items;
}

function printconnect_theme() {
  return array(
      'phonenumber' => array(
          'variables' => array('number' => '', 'attributes' => array()),
      ),
      'email' => array(
          'variables' => array('address' => '', 'attributes' => array()),
      ),
      'price' => array(
          'variables' => array(
              'value' => NULL,
              'decimals' => 2,
              'total' => FALSE,
              'block' => FALSE,
              'attributes' => array(),
              'free' => FALSE,
              'currency' => TRUE,
              'currency_symbol' => FALSE,
              'decimal_separator' => FALSE,
              'thousand_separator' => FALSE,
              'title' => FALSE,
          ),
      ),
      'address' => array(
          'variables' => array(
              'address' => NULL,
              'attributes' => array(),
          ),
      ),
      /*
        'percentage' => array(
        'variables' => array('value' => NULL, 'decimals' => 0, 'prefix' => ''),
        ),
       */
      'number' => array(
          'variables' => array(
              'value' => NULL,
              'decimals' => 0,
              'total' => FALSE,
              'block' => FALSE,
              'attributes' => array(),
              'decimal_separator' => FALSE,
              'thousand_separator' => FALSE,
              'suffix' => '',
          ),
      ),
      'priceblock' => array(
          'variables' => array(
              'subtotal' => 0,
              'vat' => $_SESSION['shop_vat'],
              'total' => 0,
              'vatAmount' => NULL,
              'attributes' => array(),
          )
      ),
      'page__empty' => array(
          'render element' => 'elements',
          'template' => 'page--empty',
      ),
      'helplink' => array(
          'variables' => array(
              'title' => t('Help'),
          ),
      ),
      'generalconditionslink' => array(
          'variables' => array(
              'title' => 'General conditions',
          ),
      ),
      'privacypolicylink' => array(
          'variables' => array(
              'title' => 'Privacy policy',
          ),
      )
  );
}

function theme_helplink($vars) {
  return l($vars['title'], variable_get('site_help', 'help'));
}

function theme_generalconditionslink($vars) {
  return l(t($vars['title']), variable_get('site_generalconditions', 'generalconditions'));
}

function theme_privacypolicylink($vars) {
  return l(t($vars['title']), variable_get('site_privacypolicy', 'privacy'));
}

function theme_price($vars) {
  $attributes = $vars['attributes'];

  if (!isset($vars['value'])) {
    $price = 0;
  } else {
    $price = $vars['value'];
  }

  if (!$vars['currency_symbol']) {
    $currencySymbol = variable_get('currency_symbol', '€');
    $currencySymbol = variable_get('printconnect_currency_symbol', '&euro;');
  } else {
    $currencySymbol = $vars['currency_symbol'];
  }

  if (!$vars['decimal_separator']) {
    $decimalSeparator = variable_get('decimal_separator', ',');
  } else {
    $decimalSeparator = $vars['decimal_separator'];
  }

  if (!$vars['thousand_separator']) {
    $thousandSeparator = variable_get('thousand_separator', '.');
  } else {
    $thousandSeparator = $vars['thousand_separator'];
  }

  $decimals = $vars['decimals'];

  if (!isset($vars['total'])) {
    $total = FALSE;
  } else {
    $total = $vars['total'];
  }

  $attributes['class'][] = 'price';

  if ($total) {
    $attributes['class'][] = 'total';
  }
  if (!isset($vars['block'])) {
    $container = 'span';
  } else {
    if ($vars['block']) {
      $container = 'div';
    } else {
      $container = 'span';
    }
  }
  if (isset($vars['currency'])) {
    $currency = $vars['currency'];
  } else {
    $currency = TRUE;
  }

  if (!isset($vars['suffix'])) {
    $suffix = '';
  } else {
    $suffix = ' ' . $vars['suffix'];
  }

  if ($price == 0 && $vars['free']) {
    $price = t('Free');
  }

  if (isset($vars['title']) && $vars['title']) {
    $title = '<label>' . $vars['title'] . '</label>';
  } else {
    $title = '';
  }

  //$attributes['decimal_separator'] = $decimalSeparator;

  if (!is_numeric($price)) {
    return '<' . $container . ' ' . drupal_attributes($attributes) . '>' . $title . '<span class="value">' . $price . $suffix . " </span></$container>";
  } else {
    $parts = explode(',', number_format($price, $decimals, ',', ''));

    $build = array(
        '#prefix' => '<' . $container . drupal_attributes($attributes) . '>',
        '#suffix' => "</$container>",
        'title' => array(
            '#markup' => $title,
        ),
        'value' => array(
            '#prefix' => '<span class="value">',
            '#suffix' => '</span>',
            'currency' => array(
                '#prefix' => '<span class="currency">',
                '#suffix' => '</span>',
                '#markup' => $currencySymbol,
                '#weight' => 0,
            ),
            'space' => array(
                '#markup' => '&nbsp;',
                '#weight' => 1,
            ),
            'whole' => array(
                '#prefix' => '<span class="whole">',
                '#suffix' => '</span>',
                '#markup' => $parts[0],
                '#weight' => 2,
            ),
            'decimalpoint' => array(
                '#prefix' => '<span class="decimalpoint">',
                '#suffix' => '</span>',
                '#markup' => ',',
                '#weight' => 3,
            ),
            'decimals' => array(
                '#prefix' => '<span class="decimals">',
                '#suffix' => '</span>',
                '#markup' => $parts[1],
                '#weight' => 4,
            ),
        ),
    );

    if ($currencySymbol == 'Dh') {
      $build['value']['space']['#weight'] = 5;
      $build['value']['currency']['#weight'] = 6;
    }


    return drupal_render($build);

    return '<' . $container . drupal_attributes($attributes) . '>' . $title . '<span class="value"><span class="currency">' . $currencySymbol . '</span>&nbsp;<span class="whole">' . $parts[0] . '</span><span class="decimalpoint">,</span><span class="decimals">' . $parts[1] . "</span></span></$container>";
  }
}

function theme_number($vars) {
  $attributes = $vars['attributes'];

  if (!isset($vars['value'])) {
    $number = 0;
  } else {
    $number = $vars['value'];
  }

  if (!$vars['decimal_separator']) {
    $decimalSeparator = variable_get('decimal_separator', ',');
  } else {
    $decimalSeparator = $vars['decimal_separator'];
  }

  if (!$vars['thousand_separator']) {
    $thousandSeparator = variable_get('thousand_separator', '.');
  } else {
    $thousandSeparator = $vars['thousand_separator'];
  }

  $attributes['class'][] = 'number';

  $attributes['decimal_separator'] = $decimalSeparator;

  if (!is_numeric($number)) {
    return '<span ' . drupal_attributes($attributes) . '>' . $number . ' ' . $vars['suffix'] . "</span>";
  } else {
//$parts = explode(',', number_format($price, $decimals, ',', '.'));
//return '<' . $container . ' class="' . $class . '">' . ($currency ? '<span class="currency">&euro;</span>&nbsp;' : '') . '<span class="whole">' . $parts[0] . '</span><span class="decimalpoint">,</span><span class="decimals">' . $parts[1] . "</span></$container>";
    return '<span ' . drupal_attributes($attributes) . '><span class="value">' . number_format($number, $vars['decimals'], $decimalSeparator, $thousandSeparator) . '</span> ' . $vars['suffix'] . '</span>';
  }
}

function theme_priceblock($vars) {
  $subtotal = $vars['subtotal'];
  if (!is_numeric($subtotal)) {
    $subtotal = 0;
  }
  if (isset($vars['vatAmount'])) {
    $vatAmount = $vars['vatAmount'];
  } else {
    $vatAmount = $subtotal * $vars['vat'];
  }
  $total = $subtotal + $vatAmount;

  $attributes = $vars['attributes'];
  $attributes['class'][] = 'priceblock';
// $attributes['class'][] = 'clearfix';


  return '<div ' . drupal_attributes($attributes) . '>'
          . theme('price', array('value' => $subtotal, 'title' => t('Total excl. VAT'), 'block' => TRUE, 'attributes' => array('class' => array('clearfix', 'subtotal'))))
          . theme('price', array('value' => $vatAmount, 'title' => t('VAT'), 'block' => TRUE, 'attributes' => array('class' => array('clearfix', 'vat'))))
          . theme('price', array('value' => $total, 'title' => t('Total incl. VAT'), 'block' => TRUE, 'attributes' => array('class' => array('clearfix', 'total')))) .
          '</div>';


  return '<div ' . drupal_attributes($attributes) . '>
            <div class="clearfix subtotal">
              <label>' . t('Total excl. VAT') . '</label>
              <span class="value total-excl-vat">' . theme('price', array('value' => $subtotal)) . '</span>
            </div>
            <div class="clearfix vat">
              <label>' . t('VAT') . '</label>
              <span class="value vat">' . theme('price', array('value' => $vatAmount)) . '</span>
            </div>
            <div class="clearfix total">
              <label>' . t('Total incl. VAT') . '</label>
              <span class="value total-incl-vat">' . theme('price', array('value' => $total, 'total' => TRUE)) . '</span>
            </div>
        </div>';

  return '<div ' . drupal_attributes($attributes) . '>
          <table>
            <tr>
              <td>' . t('Total excl. VAT') . '</td>
              <td class="value total-excl-vat">' . theme('price', array('value' => $subtotal)) . '</td>
            </tr>
            <tr>
              <td>' . t('VAT') . '</td>
              <td  class="value vat">' . theme('price', array('value' => $vatAmount)) . '</td>
            </tr>
            <tr>
              <td class="totallabel">' . t('Total incl. VAT') . '</td>
              <td  class="value total-incl-vat">' . theme('price', array('value' => $total, 'total' => TRUE)) . '</td>
            </tr>
          </table>
        </div>';
}

function theme_address($vars) {
  $address = $vars['address'];
  $attributes = $vars['attributes'];
  $attributes['class'][] = 'address';
// $result = '';
  if ($address) {

    $result['address'] = array(
        '#type' => 'container',
        '#attributes' => $attributes,
    );


//$result = '<div class="address">';

    if (isset($address->pickupPointId) && $address->pickupPointId) {
//$result .= htmlentities($address->pickupPointName) . '<br/>';
      $result['address']['pickuppoint'] = array(
          '#type' => 'container',
          '#attributes' => array('class' => array('pickuppoint')),
      );
      $result['address']['pickuppoint']['content'] = array(
          '#markup' => $address->pickupPointName,
      );
    }
    if ($address->name) {
//  if (isset($address->name) && $address->name) {
//$result .= '<div class="name">' . htmlentities($address->name) . '</div>';
      $result['address']['name'] = array(
          '#type' => 'container',
          '#attributes' => array('class' => array('name')),
      );
      $result['address']['name']['content'] = array(
          '#markup' => $address->name,
      );
    }
    if (isset($address->company) && $address->company) {
//$result .= '<div class="company">' . htmlentities($address->company) . '</div>';
      $result['address']['company'] = array(
          '#type' => 'container',
          '#attributes' => array('class' => array('company')),
      );
      $result['address']['company']['content'] = array(
          '#markup' => $address->company,
      );
    }
    if (isset($address->street) && $address->street) {
//$result .= htmlentities($address->street) . '<br/>';
      $result['address']['street'] = array(
          '#type' => 'container',
          '#attributes' => array('class' => array('street')),
      );
      $result['address']['street']['content'] = array(
          '#markup' => $address->street,
      );
    }
    $place = FALSE;
    if (isset($address->country) && $address->country) {
      $country = \printconnect\Countries\Factory::Get($address->country);
      $iso = $country->iso;
      if (isset($iso)) {
//$result .= $country->iso . '- ';
//        $result['address']['country']['content'] = array(
//            '#markup' => $country->iso . '- ',
//        );
        $place = $country->iso . ' - ';
      }
    }
    if (isset($address->postalCode) && $address->postalCode) {
//$result .= htmlentities($address->postalCode) . ' ';
//      $result['address']['postalCode']['content'] = array(
//          '#markup' => $address->postalCode . ' ',
//      );
      $place .= $address->postalCode . ' ';
    }

    if (isset($address->city) && $address->city) {
//$result .= htmlentities($address->city) . '<br/>';
//      $result['address']['city']['content'] = array(
//          '#markup' => $address->city . ' ',
//      );
      $place .= $address->city;
    }

    if ($place) {
      $result['address']['place'] = array(
          '#type' => 'container',
          '#attributes' => array('class' => array('place')),
          'content' => array(
              '#markup' => $place,
          )
      );
    }


    if (isset($address->vatNumber) && $address->vatNumber != '') {
//$result .= $address->vatNumber . '<br/>';
      $result['address']['vatNumber'] = array(
          '#type' => 'container',
          '#attributes' => array('class' => array('vatNumber')),
      );
      $result['address']['vatNumber']['content'] = array(
          '#markup' => $address->vatNumber,
      );
    }
    if (isset($address->phone) && $address->phone) {
//$result .= htmlentities($address->phone) . '<br/>';
      $result['address']['phone'] = array(
          '#type' => 'container',
          '#attributes' => array('class' => array('phone')),
      );
      $result['address']['phone']['content'] = array(
          '#markup' => $address->phone,
      );
    }
//$result .= '</div>';
  }
  return drupal_render($result);
}

function theme_phonenumber($vars) {
  $number = $vars['number'];
  $attributes = $vars['attributes'];
  $attributes['class'][] = 'phonenumber';
  return '<div ' . drupal_attributes($attributes) . '>' . $number . "</div>";
}

function theme_email($vars) {
  $address = $vars['address'];
  $attributes = $vars['attributes'];
  $attributes['class'][] = 'email';
  return l($address, 'mailto:' . $address, array('attributes' => $attributes));
}

function _printconnect_settings() {
  $options = array();
  $dals = module_invoke_all('dal_info');

  foreach ($dals as $key => $dal) {
    $options[$key] = $dal['#title'];
  }

  $form['pc_dal'] = array(
      '#type' => 'select',
      '#options' => $options,
      '#title' => t('Dal'),
      '#default_value' => variable_get('pc_dal', 'restdal'),
      '#description' => t("The Dal to use"),
  );

  $options = array();
  $paymentgateways = module_invoke_all('paymentgateway_info');

  foreach ($paymentgateways as $key => $paymentgateway) {
    $options[$key] = $paymentgateway;
  }

  $form['pc_paymentgateway'] = array(
      '#type' => 'select',
      '#options' => $options,
      '#title' => t('Payment gateway'),
      '#default_value' => variable_get('pc_paymentgateway', 'pcogone'),
      '#description' => t("The payment gateway to use"),
  );


  $form['pc_cache'] = array(
      '#type' => 'checkbox',
      '#title' => t('Use cache'),
      '#default_value' => variable_get('pc_cache', TRUE),
      '#description' => t("Use the caching mechanism."),
  );

  foreach (language_list('weight') as $languages) {
    foreach ($languages as $language) {

      $form[$language->language] = array(
          '#type' => 'fieldset',
          '#title' => $language->language,
          '#collapsible' => TRUE,
          '#collapsed' => TRUE,
      );

      $form[$language->language]['printconnect_phonenumber_' . $language->language] = array(
          '#type' => 'textfield',
          '#title' => t("Phone number"),
          '#default_value' => variable_get('printconnect_phonenumber_' . $language->language, '078 15 01 01'),
      );
      $form[$language->language]['printconnect_email_' . $language->language] = array(
          '#type' => 'textfield',
          '#title' => t("Email"),
          '#default_value' => variable_get('printconnect_email_' . $language->language, 'info@printconnect.be'),
      );
    }
  }
  return system_settings_form($form);
}

function printconnect_email() {
  global $language;
  return variable_get('printconnect_email_' . $language->language, 'info@printconnect.be');
}

function printconnect_phonenumber() {
  global $language;
  return variable_get('printconnect_phonenumber_' . $language->language, '078 15 01 01');
}

function printconnect_block_info() {
  $blocks['more'] = array(
      'info' => t('More like this'),
  );
  $blocks['progress'] = array(
      'info' => t('Progress'),
      'cache' => DRUPAL_NO_CACHE,
  );
  if (module_exists('browscap')) {
    $blocks['browserwarning'] = array(
        'info' => t('Browser compatibility warning'),
        'cache' => DRUPAL_NO_CACHE,
    );
  }

  if (variable_get('pc_cookies', FALSE)) {
    $blocks['cookies'] = array(
        'info' => t('Cookies warning'),
        'cache' => DRUPAL_NO_CACHE,
    );
  }
  return $blocks;
}

function printconnect_block_view($delta = '') {
  $args = arg();
  switch ($delta) {
    case 'more':
      if ($args[0] == 'node' && isset($args[1])) {
        $node = node_load($args[1]);
        if (isset($node) && $node) {
          global $language;
          $result = db_select('node', 'n')
                  ->fields('n', array('nid', 'title', 'created'))
                  ->condition('n.type', $node->type)
                  ->condition('n.nid', $node->nid, '<>')
                  ->condition('language', $language->language)
                  ->orderBy('created', 'DESC')
//->range(0, 50)
                  ->addTag('node_access')
                  ->execute();

//  $build['list'] = node_title_list($result);
//$block['content'] = theme('printconnect_more_block', array('nodes' => $result));
          $block['content']['more'] = array(
              '#type' => 'fieldset',
              '#title' => t('More like this'),
          );
          $block['content']['more']['list'] = array('#markup' => drupal_render(node_title_list($result)));



          return $block;
        }
      }
      break;

    case 'progress':
      $steps = module_invoke_all('progress');
      $items = array();
      $currentPath = current_path();
      $active = FALSE;
      $block = FALSE;
      $listClass = '';

      $i = 0;
      foreach (element_children($steps, TRUE) as $key) {
        $i++;
        $item = $steps[$key];
        $class = array('step' . $i);
        if (in_array($currentPath, $item['paths'])) {
          $active = TRUE;
          $class[] = 'active';
          $activeItem = $i - 1;
          $listClass = 'step' . $i . '-active';
        }

        $items[] = array(
            'data' => l($item['title'], $item['paths'][0]),
            'class' => $class,
        );
      }
      if ($active) {

        foreach ($items as $key => $value) {
          if ($key == $activeItem) {
            break;
          }
          $items[$key]['class'][] = 'done';
        }

        $block['content'] = array(
            '#theme' => 'item_list',
            '#items' => $items,
            '#attributes' => array('class' => array('clearfix', $listClass)),
        );

        return $block;
      }

      break;
    case 'browserwarning':
      global $browscap;

//      
//      if (!$browscap) {
//        $block['content'] = array(
//            '#type' => 'container',
//            '#attributes' => array('class' => array('browserwarning')),
//            'warning' => array(
//                '#markup' => 'Your browser is out of date, and may not be compatible with our website.',
//            ),
//        );
//        

      if ((!isset($_SESSION['printconnect_browserwarning']) || !$_SESSION['printconnect_browserwarning']) && !$browscap) {
        $block['content']['form'] = drupal_get_form('printconnect_browserwarning_form');
        return $block;
      }

      //}
      break;

    case 'cookies':
      if (variable_get('pc_cookies', FALSE) && !$_SESSION['printconnect_cookies']) {
        $block['content']['form'] = drupal_get_form('printconnect_cookies_form');
        return $block;
      }


      break;
  }
}

function _printconnect_js_callback() {
  $args = func_get_args();
  $action = array_shift($args);

  switch ($action) {
    case 'country':
      $id = array_shift($args);
      $country = \printconnect\Countries\Factory::Get($id);
      $country->EnsureLoaded();
      return drupal_json_output($country->properties);
  }
}

function printconnect_mail($key, &$message, $params) {
// $data['user'] = $params['account'];
// $options['language'] = $message['language'];
//user_mail_tokens($variables, $data, $options);
  switch ($key) {
    case 'error':
//      $langcode = $message['language']->language;
      $message['subject'] = 'An exception occurred';
      $message['body'][] = url($_GET['q'], array('absolute' => true));
      $message['body'][] = 'Referer : ' . isset($_SERVER['HTTP_REFERER']) ? $_SERVER['HTTP_REFERER'] : '';
      if (isset($params['exception'])) {
        $message['body'][] = print_r($params['exception'], true);
      }
      if (isset($params['message'])) {
        $message['body'][] = $params['message'];
      }
      $message['body'][] = print_r($_REQUEST, true);

//$message['subject'] = t('Notification from !site', $variables, array('langcode' => $langcode));
//$message['body'][] = t("Dear !username\n\nThere is new content available on the site.", $variables, array('langcode' => $langcode));
      break;
    case 'watchdog':
//      $vars = isset($params['variables']) ? $params['variables'] : array();
//$message['subject'] = strip_tags(t($params['message'], $vars));
      $message['subject'] = t('Watchdog entry of severity @severity', array('@severity' => $params['severity']));
      $message['body'][] = print_r($params, true);
      $message['body'][] = print_r($_REQUEST, true);
      break;
  }
}

function printconnect_watchdog($log_entry) {
  if ($log_entry['severity'] < 4) {
    if (function_exists('drupal_mail')) {
      drupal_mail('printconnect', 'watchdog', variable_get('site_mail', 'ewald.de.wreede@printconcept.com'), 'nl', $log_entry);
    }
  }
}

function printconnect_exit($destination = NULL) {
  if (!isset($destination)) {
//    \printconnect\Diagnostics\Debug::Clear();
  }
  //unset($_COOKIE);
}

function printconnect_preprocess_page(&$vars) {

  if (isset($_GET['contentonly'])) {
    $contentOnly = $_GET['contentonly'];
    if (is_array($contentOnly)) {
      
    } else {
      unset($vars['logo']);
    }

    $vars['theme_hook_suggestion'] = 'page__empty';


//$vars['theme_hook_suggestion'] = 'page__empty';
//    foreach (element_children($vars['page']) as $region) {
//      if ($region != 'content') {
//        unset($vars['page'][$region]);
////        foreach (element_children($vars['page'][$region]) as $block) {
////          if ($block != 'system_main' && $block != 'pccart_cart' && $block != 'pclivecom_smallchat' && $block != 'printconnect_progress' && $block != 'pcpayments_secure' && $block != 'pcdevel_debug') {
////            hide($vars['page'][$region][$block]);
////          }
////        }
//      }
//    }
  }


//$vars['logo'] = $GLOBALS['base_url'] . $vars['logo'];

  if (isset($vars['node'])) {
    $vars['theme_hook_suggestions'][] = 'page__' . str_replace('_', '-', $vars['node']->type);
    $vars['theme_hook_suggestions'][] = 'page__' . str_replace('_', '-', $vars['node']->type) . '__' . $vars['node']->nid;
  }

  //drupal_add_css(theme_get_setting('pc_css'), array('group' => CSS_THEME, 'type' => 'inline', 'every_page' => TRUE, 'weight' => 100));
}

function printconnect_getimage($type, $id) {
  global $theme_key;
  $image = FALSE;

  //$paths = &drupal_static(__FUNCTION__ . 'paths');
  $paths = cache_get('printconnect_getimage_paths');

  if (!$paths) {
    $paths = module_invoke_all('getimagepath');
    drupal_alter('getimagepath', $paths);
    cache_set('printconnect_getimage_paths', $paths);
  } else {
    $paths = $paths->data;
  }


  //$images = &drupal_static(__FUNCTION__ . 'images');
  $images = cache_get('printconnect_getimage_images');

  if (!$images) {
    $images = array();
  } else {
    $images = $images->data;
  }


  if (array_key_exists($type, $images) && array_key_exists($id, $images[$type])) {
    return $images[$type][$id];
  }

  if (isset($paths[$type])) {
    $path = $paths[$type];
    $themePath = drupal_get_path('theme', $theme_key);
    $file = '/' . $path['path'] . '/' . $id . '.' . $path['extension'];
    $themeFile = $themePath . $file;
    if (file_exists($themeFile)) {
      $image = $themeFile;
    } else {
      $url = variable_get('pc_images', 'http://images.printconcept.com/site') . $file;
      $fp = @fopen($url, 'r');
      if ($fp) {
        fclose($fp);
        $image = variable_get('pc_images', 'http://images.printconcept.com/site') . $file;
      } else {
        $image = drupal_get_path('module', $path['module']) . '/images' . $file;
      }
    }
    $images[$type][$id] = $image;

    cache_set('printconnect_getimage_images', $images);
  }
  return file_create_url($image);
}

function printconnect_getimagepath() {
  return array(
      'paymentmethods' => array(
          'module' => 'printconnect',
          'path' => 'paymentmethods',
          'extension' => 'png'
      ),
      'shipping' => array(
          'module' => 'printconnect',
          'path' => 'shipping',
          'extension' => 'png'
      )
  );
}

function printconnect_language_switch_links_alter(array &$result, $type, $path) {
  global $conf;
//  unset($result['en']);

  if (isset($conf['languages'])) {
    $languages = $conf['languages'];
    if ($languages && count($languages)) {
      foreach ($result as $key => $language) {
        if ($languages && count($languages) && !in_array($key, $languages)) {
          unset($result[$key]);
        }
      }

      if (count($result) == 1) {
        $result = array();
      }
    }
  }
$prefix ='.be/frfr';
$queryprefix = $GLOBALS['base_url'].'/'.request_path();
$pathPrefix = $GLOBALS['base_url'].'/befr';

if( strstr($queryprefix, $prefix)) {
drupal_goto($pathPrefix , array('language' => $newLanguage, 'query' => $query), 301);
} 
//  foreach ($result as $key => $value) {
//    $path = path_load(array(
//                'source' => $language['href'],
//                'language' => $key,
//            ));
//    if ($path) {
//      $result[$key]['href'] = $path['alias'];
//    }
//  }
}

function printconnect_form_system_site_information_settings_alter(&$form, &$form_state) {
  $form['printconnect'] = array(
      '#type' => 'fieldset',
      '#title' => 'PrintConnect',
  );
  $form['printconnect']['site_help'] = array(
      '#type' => 'textfield',
      '#title' => t('Help page'),
      '#default_value' => variable_get('site_help', 'help'),
      '#required' => TRUE,
      '#description' => t('Specify a relative URL to display as the help page.'),
      '#field_prefix' => url(NULL, array('absolute' => TRUE)) . (variable_get('clean_url', 0) ? '' : '?q='),
  );
  $form['printconnect']['site_generalconditions'] = array(
      '#type' => 'textfield',
      '#title' => t('General conditions'),
      '#default_value' => variable_get('site_generalconditions', 'generalconditions'),
      '#required' => TRUE,
      '#description' => t('Specify a relative URL to display as the general conditions page.'),
      '#field_prefix' => url(NULL, array('absolute' => TRUE)) . (variable_get('clean_url', 0) ? '' : '?q='),
  );
  $form['printconnect']['site_privacypolicy'] = array(
      '#type' => 'textfield',
      '#title' => t('Privacy policy'),
      '#default_value' => variable_get('site_privacypolicy', 'privacy'),
      '#required' => TRUE,
      '#description' => t('Specify a relative URL to display as the privacy policy page.'),
      '#field_prefix' => url(NULL, array('absolute' => TRUE)) . (variable_get('clean_url', 0) ? '' : '?q='),
  );
}

function printconnect_form_system_theme_settings_alter(&$form, &$form_state) {

  if (isset($form_state['build_info']['args'][0]) && ($theme = $form_state['build_info']['args'][0])) {
    $form['printconnect'] = array(
        '#type' => 'fieldset',
        '#title' => t('PrintConnect'),
        '#description' => t('Addtional settings')
    );
    $form['printconnect']['printconnect_css'] = array(
        '#type' => 'textarea',
        '#title' => t('Additional css to be loaded in this theme'),
        '#default_value' => theme_get_setting('printconnect_css', $theme),
        '#description' => t('Specify extra css rules to be loaded in the theme, do not use the &lt;style&gt; tag.'),
    );

//    $form['color'] += color_scheme_form($form, $form_state, $theme);
//    $form['#validate'][] = 'color_scheme_form_validate';
//    $form['#submit'][] = 'color_scheme_form_submit';
  }
}

function printconnect_form_system_regional_settings_alter(&$form, &$form_state) {
  $form['printconnect'] = array(
      '#type' => 'fieldset',
      '#title' => t('PrintConnect'),
      '#description' => t('Addtional settings')
  );
  $form['printconnect']['printconnect_currency_symbol'] = array(
      '#type' => 'select',
      '#options' => array(
          '&euro;' => 'Euro',
          'Dh' => 'Moroccan Dirham',
          '£' => 'British pounds',
      ),
      '#title' => t('The currency to be used when displaying prices'),
      '#default_value' => variable_get('printconnect_currency_symbol', '&euro;'),
  );

//    $form['color'] += color_scheme_form($form, $form_state, $theme);
//    $form['#validate'][] = 'color_scheme_form_validate';
//    $form['#submit'][] = 'color_scheme_form_submit';
}

function printconnect_form_search_form_alter(&$form, $form_state) {
  $form['basic']['keys']['#description'] = t('Search');
}

function printconnect_form_search_block_form_alter(&$form, $form_state) {
  $form['search_block_form']['#description'] = t('Search');
}

function printconnect_variable_info($options) {
  $variables['site_help'] = array(
      'type' => 'string',
      'title' => t('Help page', array(), $options),
      'default' => 'help',
      'description' => t('The help page of this website.', array(), $options),
      'required' => TRUE,
      'group' => 'site_information',
  );
  $variables['site_generalconditions'] = array(
      'type' => 'string',
      'title' => t('General conditions', array(), $options),
      'default' => 'generalconditions',
      'description' => t('The general conditions page of this website.', array(), $options),
      'required' => TRUE,
      'group' => 'site_information',
  );
  $variables['site_privacypolicy'] = array(
      'type' => 'string',
      'title' => t('Privacy policy', array(), $options),
      'default' => 'privacy',
      'description' => t('The privacy policy page of this website.', array(), $options),
      'required' => TRUE,
      'group' => 'site_information',
  );
  return $variables;
}

function printconnect_page_alter(&$page) {
  $breadcrumb = drupal_get_breadcrumb();
  if(preg_match('/taxonomy\/term\/all/', $breadcrumb[1])) {
      unset($breadcrumb[1]);
      drupal_set_breadcrumb($breadcrumb);
  }
  drupal_add_css(theme_get_setting('printconnect_css'), array('group' => CSS_THEME, 'type' => 'inline', 'every_page' => TRUE, 'weight' => 100));
  $page['page_bottom']['loading'] = array(
      '#type' => 'container',
      '#attributes' => array('class' => array('loading')),
      'overlay' => array(
          '#type' => 'container',
          '#attributes' => array('class' => array('overlay')),
      ),
      'content' => array(
          '#type' => 'container',
          '#attributes' => array('class' => array('message')),
          'content' => array(
              '#markup' => t('Loading'),
          )
      )
  );
}

function printconnect_filter_info() {
  $filters = array();
  $filters['copycontent'] = array(
      'title' => t('Copy content'),
      'description' => t('Copies another part into this'),
      'process callback' => 'printconnect_copycontent',
      'cache' => FALSE,
  );
  $filters['replaceimageurls'] = array(
      'title' => t('Replace image urls'),
      'description' => t('Replaces the image urls with link to a CDN'),
      'process callback' => 'printconnect_replaceimageurls',
      'tips callback' => '_printconnect_filter_tips',
      'cache' => FALSE,
  );
  return $filters;
}

function _printconnect_filter_tips($filter, $format, $long) {
  switch ($filter->name) {
    case 'replaceimageurls':


      $replaceImagePaths = variable_get('pc_images_replace', array('http://images.printconcept.com/'));
      $images = variable_get('pc_images', 'https://printconnectimages.s3.amazonaws.com/');

      if ($long) {

        $build['title'] = array(
            '#prefix' => '<h4>',
            '#suffix' => '</h4>',
            '#markup' => 'Image url replacement',
        );

        $build['replacing']['text'] = array(
            '#markup' => 'Following images urls',
        );
        $build['replacing']['list'] = array(
            '#theme' => 'item_list',
            '#items' => $replaceImagePaths,
        );
        $build['replacement'] = array(
            '#markup' => 'will be replaced with ' . $images,
        );

        return drupal_render($build);
      } else {
        $replaceImagePaths = implode(', ', $replaceImagePaths);
        return 'Replace all image urls (' . $replaceImagePaths . ') with a cdn url (' . $images . ')';
      }
      break;
  }
}

function printconnect_copycontent($code) {
  preg_match_all("/\{([^\}]*)\}/", $code, $matches);

  foreach ($matches[0] as $match) {
    $item = json_decode($match);
    if ($item) {
      switch ($item->type) {
        case 'block':
          $block = module_invoke($item->module, 'block_view', $item->block);
          $output = $block['content'];
          if (is_array($output)) {
            $output = drupal_render($block['content']);
          }
          $code = str_replace($match, $output, $code);
          break;
        case 'form':
          $args = $item->args;
          // module_load_include('module', $item->module);
          if (isset($item->file)) {
            module_load_include('inc', $item->module, $item->module . '.' . $item->file);
          }
          $form = drupal_get_form($item->form, $args);
          $output = drupal_render($form);
          $code = str_replace($match, $output, $code);
          break;
      }
    }
  }
  return $code;
}

function printconnect_replaceimageurls($code) {
  $replaceImagePaths = variable_get('pc_images_replace', array('http://images.printconcept.com/'));
  $images = variable_get('pc_images', 'https://printconnectimages.s3.amazonaws.com/');
  foreach ($replaceImagePaths as $path) {
    $code = str_replace($path, $images, $code);
  }
  return $code;
}

/**
 * fix block translation().
 */
function printconnect_form_i18n_string_translate_page_form_alter(&$form, &$form_state, $form_id) {

  foreach ($form['strings']['all'] as $name => $field) {
    // The field for [ block title / vocabulary name / vocabulary description / term name ] are textfields in ori language,
    // but textareas when translating: change these to textfields.
    if (
            preg_match('/blocks:block:[0-9]+:title/i', $name) ||
            preg_match('/taxonomy:(vocabulary|term):[0-9]+:name/i', $name) ||
            preg_match('/taxonomy:vocabulary:[0-9]+:description/i', $name)
    ) {
      $form['strings']['all'][$name]['#type'] = 'textfield';
    }
    // Change textarea to text_format and overwrite description which is already auto included in text_format fields.
    elseif (
            preg_match('/blocks:block:[0-9]+:body/i', $name) ||
            preg_match('/taxonomy:term:[0-9]+:description/i', $name)
    ) {
      $form['strings']['all'][$name]['#type'] = 'text_format';
      $form['strings']['all'][$name]['#description'] = '<br />';
    }
  }

  // Add submit function.
  $form['#submit'] = array_merge(array('printconnect_form_i18n_string_translate_page_form'), $form['#submit']);
}

function printconnect_form_i18n_string_translate_page_form($form, &$form_state) {
  // Remove wysiwyg format because i18n cant handle it.
  foreach ($form_state['values']['strings'] as $name => $field) {
    if (
            preg_match('/blocks:block:[0-9]+:body/i', $name) ||
            preg_match('/taxonomy:term:[0-9]+:description/i', $name)
    ) {
      unset($form_state['values']['strings'][$name]['format']);
    }
  }
}

function printconnect_url_name($value, $separator = '-') {
  $pattern = '/[^a-zA-Z0-9]+/';

  $output = html_entity_decode($value);
  $output = strtolower(trim($output));
  $output = str_replace(array('é', 'è', 'ë', 'ê', 'à', 'á', 'â', 'ó', 'ô', 'í'), array('e', 'e', 'e', 'e', 'a', 'a', 'a', 'o', 'o', 'i'), $output);

  $output = preg_replace($pattern, $separator, $output);

  return $output;
}

function printconnect_preprocess_link(&$vars) {
  if (_printconnect_in_active_trail($vars['path'])) {
    $vars['options']['attributes']['class'][] = 'active-trail';
  }
}

function _printconnect_in_active_trail($path) {
  $active_paths = &drupal_static(__FUNCTION__);

  // Gather active paths.
  if (!isset($active_paths)) {
    $active_paths = array();
    $trail = menu_get_active_trail();
    foreach ($trail as $item) {
      if (!empty($item['href'])) {
        $active_paths[] = $item['href'];
      }
    }
  }
  if ($path == '<front>' && count($active_paths) > 1) {
    return FALSE;
  }
  if ($path == '<front>') {
    return FALSE;
  }

  return in_array($path, $active_paths);
}

function printconnect_date_format_types() {
  return array(
      'weekday' => t('Weekday'),
      'weekdayhour' => t('Weekday and hour'),
  );
}

function printconnect_date_formats() {
  return array(
      array(
          'type' => 'weekday',
          'format' => 'l',
          'locales' => array(),
      ),
      array(
          'type' => 'weekdayhour',
          'format' => 'l H:i\h',
          'locales' => array(),
      ),
      array(
          'type' => 'short',
          'format' => 'd/m/Y',
          'locales' => array(),
      ),
      array(
          'type' => 'medium',
          'format' => 'd/m/Y H:i',
          'locales' => array(),
      ),
  );
}

function printconnect_html_head_alter(&$vars) {
  $vars['X-UA-Compatible'] = array(
      '#type' => 'html_tag',
      '#tag' => 'meta',
      '#attributes' => array(
          'http-equiv' => 'X-UA-Compatible',
          'content' => 'IE=edge',
      ),
      '#weight' => -10000);

  return $vars;
}

function printconnect_cookies_form($form, &$form_state) {
  $site = variable_get('site_name', 'This site');
  $text = t('@site uses cookies to enhance your experience. !link', array('@site' => $site, '!link' => theme('privacypolicylink')));
  $form['text'] = array(
      '#prefix' => '<span class="text">',
      '#suffix' => '</span>',
      '#markup' => $text,
  );



  $form['agree'] = array(
      '#type' => 'submit',
      '#value' => t('I agree'),
  );
  return $form;
}

function printconnect_cookies_form_submit($form, &$form_state) {
  $_SESSION['printconnect_cookies'] = TRUE;
}

function printconnect_browserwarning_form($form, &$form_state) {
  $text = t('Your browser appears to be out of date, and may not be compatible with our website.');
  $form['text'] = array(
      '#prefix' => '<span class="text">',
      '#suffix' => '</span>',
      '#markup' => $text,
  );

  $form['accept'] = array(
      '#type' => 'submit',
      '#value' => t('I accept'),
  );
  return $form;
}

function printconnect_browserwarning_form_submit($form, &$form_state) {
  $_SESSION['printconnect_browserwarning'] = TRUE;
}

//fix search results
function printconnect_query_node_access_alter(QueryAlterableInterface $query) {
  $search = FALSE;
  $node = FALSE;

  // Even though we know the node alias is going to be "n", by checking for the
  // search_index table we make sure we're on the search page. Omitting this step will
  // break the default admin/content page.
  foreach ($query->getTables() as $alias => $table) {
    if ($table['table'] == 'search_index') {
      $search = $alias;
    } elseif ($table['table'] == 'node') {
      $node = $alias;
    }
  }

  // Make sure we're on the search page.
  if ($node && $search) {
    $db_and = db_and();
    // I guess you *could* use global $language here instead but this is safer.
    $language = i18n_language_interface();
    $lang = $language->language;

    $db_and->condition($node . '.language', $lang, '=');
    $query->condition($db_and);
  }
}