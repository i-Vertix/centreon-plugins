<?php

// retrieve longopts from call
$longopt                    = array();
$longopt['mssUser']         = 'p1:';
$longopt['mssPwd']          = 'p2:';
$longopt['mssSource']       = 'p3:';
$longopt[]                  = 'p4:';
$longopt['thw_requesttime'] = 'th1w:';
$longopt['thc_requesttime'] = 'th1c:';
$longopt['thw_msstime']     = 'th2w:';
$longopt['thc_msstime']     = 'th2c:';
$longopt['thw_hotelstotal'] = 'th3w:';
$longopt['thc_hotelstotal'] = 'th3c:';
$longopt['thw_hotelsavail'] = 'th4w:';
$longopt['thc_hotelsavail'] = 'th4c:';

$mssUser         = '';
$mssPwd          = '';
$mssSource       = '';
$thw_requesttime = '';
$thc_requesttime = '';
$thw_msstime     = '';
$thc_msstime     = '';
$thw_hotelstotal = '';
$thc_hotelstotal = '';
$thw_hotelsavail = '';
$thc_hotelsavail = '';


$options = getopt('', $longopt);

if ($options && count($options) > 0) {
    foreach ($longopt as $variableName => $optionName) {
        $optionName = trim($optionName, ':');
        if (array_key_exists($optionName, $options)) {
            if (is_string($variableName)) {
                $$variableName = $options[$optionName];
            } else {
                $$optionName = $options[$optionName];
            }
        }
    }
}

if (empty($mssUser) || empty($mssPwd)) {
    echo "Credentials missing (param1, param2)";
    exit(3);
}
if (empty($mssSource)) {
    echo "Source missing (param3)";
    exit(3);
}

// Function to check values against thresholds
function checkAgainstThreshold($value, $threshold)
{

    // Split the threshold by ":"
    $thresholdValues = explode(':', $threshold);

    // Extract min and max values
    $min = isset($thresholdValues[0]) && $thresholdValues[0] !== '' ? (float)$thresholdValues[0] : null;
    $max = isset($thresholdValues[1]) ? (float)$thresholdValues[1] : null;

    if (
        (isset($min) && $value > $min) ||
        (isset($max) && $value < $max)
    ) {
        return true;  // is in range
    } else {
        return false;  // is out of range
    }
}


$output     = "";
$perfOutput = "";

$datefrom = date('Y-m-d', strtotime('+2 days'));
$dateto   = date('Y-m-d', strtotime('+3 days'));

$endpoint   = "https://www.easymailing.eu/mss/mss_service.php?VERSION=2.0&function=getHotelList&mode=0";
$requestXml = <<<XML
<?xml version="1.0"?>
<root>
  <version>2.0</version>
  <header>
    <credentials>
      <user>$mssUser</user>
      <password>$mssPwd</password>
      <source>$mssSource</source>
    </credentials>
    <method>getHotelList</method>
    <paging>
      <start>0</start>
      <limit>0</limit>
    </paging>
    <result_id/>
  </header>
  <request>
    <search>
      <lang>de</lang>
      <id_ofchannel>hgv</id_ofchannel>
      <search_offer>
        <channel_id>hgv</channel_id>
        <arrival>$datefrom</arrival>
        <departure>$dateto</departure>
        <service>0</service>
        <room>
          <room_seq>1</room_seq>
          <room_type>0</room_type>
          <person>18</person>
          <person>18</person>
        </room>
      </search_offer>
    </search>
    <options>
      <disable_cache>1</disable_cache>
    </options>
    <order/>
    <logging>
      <step/>
    </logging>
  </request>
</root>
XML;


// Initialize cURL session
$ch = curl_init($endpoint);

// Set cURL options
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, $requestXml);
curl_setopt($ch, CURLOPT_HTTPHEADER, array(
    'Content-Type: application/xml',
    'Content-Length: ' . strlen($requestXml)
));

$response = curl_exec($ch);

// Check for cURL errors
if (curl_errno($ch)) {
    echo "Curl error: " . curl_error($ch) . "\n";
    exit(2);
}

$httpCode  = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$totalTime = curl_getinfo($ch, CURLINFO_TOTAL_TIME);
$perfOutput .= " 'request.time'=$totalTime;$thw_requesttime;$thc_requesttime";

curl_close($ch);


// Load the XML string
$xml = simplexml_load_string($response);

// Extract data using XPath
$errorCodeNodes = $xml->xpath('/root/header/error/code');
$errorMessageNodes = $xml->xpath('/root/header/error/message');

$errorCode = isset($errorCodeNodes[0]) ? (string) $errorCodeNodes[0] : null;
$errorMessage = isset($errorMessageNodes[0]) ? (string) $errorMessageNodes[0] : '';

if ($errorCode !== '0') {
    echo "MSS Error: $errorCode - $errorMessage";
    exit(2);
}

$timeNodes  = $xml->xpath('/root/header/time');
$mssTime    = !empty($timeNodes) ? (string)$timeNodes[0] : '';
$mssTime    = trim($mssTime, ' ms');
$mssTime    = str_replace(',', '', $mssTime);
$mssTime    = (float)$mssTime;
$mssTime    /= 1000;
$perfOutput .= " 'mss.time'=$mssTime;$thw_msstime;$thc_msstime";


$totalNodes  = $xml->xpath('/root/header/paging/total');
$totalHotels = !empty($totalNodes) ? (int)$totalNodes[0] : null;
$perfOutput  .= " 'mss.hotels.total'=$totalHotels;$thw_hotelstotal;$thc_hotelstotal";

$debugEntriesNodes = $xml->xpath('/root/debug/entries');
$debugEntries      = !empty($debugEntriesNodes) ? array_map('strval', $debugEntriesNodes) : [];

$availHotels = null;
foreach ($debugEntries as $debugEntry) {
    // Use regular expression to match the first numeric value before the first '/'
    if (preg_match('/\b(\d+)\b/', $debugEntry, $matches)) {
        $value       = $matches[1];
        $availHotels += (int)$value;
    }
}
$perfOutput .= " 'mss.hotels.available'=$availHotels;$thw_hotelsavail;$thc_hotelsavail";


$alarms   = [];
$warnings = false;
$critical = false;

if ($httpCode !== 200) {
    $critical = true;
    $alarms[] = 'HTTP Code - ' . $httpCode;
}

// perform threshold checks
if (checkAgainstThreshold($totalTime, $thc_requesttime)) {
    $critical = true;
    $alarms[] = 'Request time - ' . $totalTime;
} else if (checkAgainstThreshold($totalTime, $thw_requesttime)) {
    $warnings = true;
    $alarms[] = 'Request time - ' . $totalTime;
}

if (checkAgainstThreshold($mssTime, $thc_msstime)) {
    $critical = true;
    $alarms[] = 'MSS elaboration time - ' . $mssTime;
} else if (checkAgainstThreshold($mssTime, $thw_msstime)) {
    $warnings = true;
    $alarms[] = 'MSS elaboration time - ' . $mssTime;
}

if (is_null($totalHotels) || checkAgainstThreshold($totalHotels, $thc_hotelstotal)) {
    $critical = true;
    $alarms[] = 'Total Hotels - ' . $totalHotels;
} else if (checkAgainstThreshold($totalHotels, $thw_hotelstotal)) {
    $warnings = true;
    $alarms[] = 'Total Hotels - ' . $totalHotels;
}

if (is_null($availHotels) || checkAgainstThreshold($availHotels, $thc_hotelsavail)) {
    $critical = true;
    $alarms[] = 'Bookable Hotels - ' . $availHotels;
} else if (checkAgainstThreshold($availHotels, $thw_hotelsavail)) {
    $warnings = true;
    $alarms[] = 'Bookable Hotels - ' . $availHotels;
}


if ($critical) {
    $exitstatus = 2;
} else if ($warnings) {
    $exitstatus = 1;
} else {
    $exitstatus = 0;
    $output = 'All metrics OK - ' . $output;
}

$output .= implode(', ', $alarms);

echo "$output |$perfOutput";
exit ($exitstatus);