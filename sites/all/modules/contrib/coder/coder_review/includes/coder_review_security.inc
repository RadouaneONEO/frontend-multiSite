<?php
// $Id: coder_review_security.inc,v 1.3 2009/10/18 12:45:36 snpower Exp $

/**
 * @file
 * This include file implements coder functionality for Drupal Standards.
 *
 * @todo The rules for this review are not yet complete.
 */

/**
 * Implements hook_reviews().
 */
function coder_review_security_reviews() {
  $table = '\{[A-Za-z_]+\}'; // table-regex
  $rules = array(
    array(
      '#type' => 'regex',
      '#value' => '[\s\(]l\(check_plain\(.*',
      '#never' => '[\'"]html[\'"]\s*=>\s*(TRUE|1)',
      '#source' => 'allphp',
      '#warning_callback' => '_coder_review_security_l_check_plain_warning',
    ),
/*  array(
      '#type' => 'callback',
      '#value' => _coder_review_security_callback,
    ), */
    array(
      '#type' => 'regex',
      '#value' => '(?-i)\$REQUEST_URI',
      '#warning_callback' => '_coder_review_security_request_uri_warning',
    ),
    array(
      '#type' => 'regex',
      '#source' => 'allphp',
      '#value' => '(?-i)\"REQUEST_URI\"|\'REQUEST_URI\'',
      '#warning_callback' => '_coder_review_security_request_uri_warning',
    ),
    array(
      '#type' => 'regex',
      '#value' => '^(select\s+.*\s+from\s+' . $table . '|insert\s+into\s+' . $table . '|update\s+' . $table . '\s+set|delete\s+from\s+' . $table . ')\s+.*\$[a-z0-9_]+',
      '#not' => '\$placeholder',
      '#never' => '[\s\(]update_sql\(',
      '#source' => 'quote',
      '#warning_callback' => '_coder_review_security_sql_var_warning',
    ),
    array(
      '#type' => 'regex',
      '#value' => '^(select\s+.*\s+from\s+' . $table . '|insert\s+into\s+' . $table . '|update\s+' . $table . '\s+set|delete\s+from\s' . $table . ')\s+[^\']*?(\s+|\(|=|,)\%s',
      '#source' => 'quote',
      '#warning' => 'SQL query handling data in a potentially insecure way by using the %%s placeholder without wrapping it in single quotes.  This is a potential source of SQL injection attacks when the value can come from user data.',
    ),
  );
  $review = array(
    '#title' => 'Drupal Security Checks',
    '#link' => 'http://drupal.org/node/28984',
    '#rules' => $rules,
    '#severity' => 'critical',
    '#description' => t('very basic, needs work, but what it finds is good'),
  );
  return array('security' => $review);
}


/**
 * Define the rule callbacks.
 */

/* function _coder_review_security_callback(&$coder_args, $review, $rule, $lines, &$results) {
  if (!isset($coder_args['#tokens'])) {
    $source = implode('', $lines);
    $coder_args['#tokens'] = token_get_all($source);
  }
} */

/**
 * Define the warning callbacks.
 */

function _coder_review_security_l_check_plain_warning() {
  return t('!l() already contains a !check_plain() call by default',
    array(
      '!l' => theme('drupalapi', array('function' => 'l')),
      '!check_plain' => theme('drupalapi', array('function' => 'check_plain')),
    )
  );
}

function _coder_review_security_request_uri_warning() {
  return t('the use of REQUEST_URI is prone to XSS exploits and does not work on IIS; use !request_uri() instead',
    array(
      '!request_uri' => theme('drupalapi', array('function' => 'request_uri')),
    )
  );
}

function _coder_review_security_sql_var_warning() {
  return array(
    '#warning' => t('In SQL strings, Use !db_query() placeholders in place of variables.  This is a potential source of SQL injection attacks when the variable can come from user data.',
      array(
        '!db_query' => theme('drupalapi', array('function' => 'db_query')),
      )
    ),
    '#link' => 'http://drupal.org/writing-secure-code',
    '#description' => t('Use %s and %d variable substitution.  When inserting an array of values use <code>$placeholders = implode(\',\', array_fill(0, count($args), "\'%s\'"));</code>'),
  );
}
