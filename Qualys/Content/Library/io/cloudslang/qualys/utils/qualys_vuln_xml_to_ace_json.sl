namespace: io.cloudslang.qualys.utils
operation:
  name: qualys_vuln_xml_to_ace_json
  inputs:
    - xml_input
  python_action:
    use_jython: false
    script: "# do not remove the execute function\ndef execute(xml_input):\n    import xml.etree.ElementTree as ET\n    import re\n    \n    # Parse the XML content\n    root = ET.fromstring(xml_input)\n    \n    vulnerabilities = []\n    unique_qids = set()\n    # Function to extract vulnerability details from an XML element\n    def extract_vulnerability(vuln_element):\n    # Extracting CVSS score\n        cvss_score = None\n        for qds_factor in vuln_element.findall('.//QDS_FACTOR'):\n            if qds_factor.get('name') == 'CVSS':\n                cvss_score = float(qds_factor.text) if qds_factor.text else None\n                break\n        \n        qid = vuln_element.find('QID').text if vuln_element.find('QID') is not None else None\n        \n        if qid in unique_qids:\n            # Skip if QID is already seen\n            return None\n        else:\n            unique_qids.add(qid)\n        \n        vulnerability = {\n            \"sourceId\": qid,\n            \"type\": vuln_element.find('TYPE').text if vuln_element.find('TYPE') is not None else None,\n            \"severity\": vuln_element.find('SEVERITY').text if vuln_element.find('SEVERITY') is not None else None,\n            \"status\": vuln_element.find('STATUS').text if vuln_element.find('STATUS') is not None else None,\n            \"firstDetected\": vuln_element.find('FIRST_FOUND_DATETIME').text if vuln_element.find('FIRST_FOUND_DATETIME') is not None else None,\n            \"lastDetected\": vuln_element.find('LAST_FOUND_DATETIME').text if vuln_element.find('LAST_FOUND_DATETIME') is not None else None,\n            \"CVSS\": cvss_score\n        }\n        return vulnerability\n\n    # Extracting vulnerabilities\n    for host in root.findall('.//HOST'):\n        for vuln in host.findall('.//DETECTION'):\n            extracted_vuln = extract_vulnerability(vuln)\n            if extracted_vuln:\n                vulnerabilities.append(extracted_vuln)\n            \n    qid_list = ','.join(filter(None, unique_qids))\n    \n    # Extract warnings\n    warning_code = None\n    warning_text= None\n    warning_url = None\n    id_min = None\n    for warning in root.findall('.//WARNING'):\n        warning_code = int(warning.find('CODE').text) if warning.find('CODE') is not None else None\n        warning_text = warning.find('TEXT').text if warning.find('TEXT') is not None else None\n        warning_url = warning.find('URL').text if warning.find('URL') is not None else None\n        \n    if (warning_url is not None):\n        match = re.search(r'id_min=(\\d+)', warning_url)\n         # Extract and return the value if found\n        if match:\n            id_min = match.group(1)\n    \n    # Creating the final object\n    return {\"vulnerabilities\": vulnerabilities, \"unique_qid_list\":qid_list, \"warning_code\":warning_code, \"warning_text\":warning_text, \"warning_url\":warning_url, \"id_min\":id_min }\n\n# you can add additional helper methods below."
  outputs:
    - vulnerabilities
    - unique_qid_list
    - warning_code
    - warning_text
    - warning_url
    - id_min
  results:
    - HAS_MORE: '${warning_code == "1980"}'
    - SUCCESS
