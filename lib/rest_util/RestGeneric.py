import json
import urllib3
import pandas as pd
import os
import sys
import six
import requests
from functools import reduce
import operator
import datetime
from datetime import date

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

cwd = os.path.abspath(os.path.dirname(__file__))
project_path = cwd.split('\\lib')[0]
if project_path not in sys.path:
    sys.path.append(project_path)

from pandas import ExcelFile
from robot.api import logger as log
from six import iteritems
from six.moves.urllib.parse import quote


class RestGeneric(object):
    def __init__(self):
        self.mismatch = []

    @staticmethod
    def create_base_url(appserver_host, appserver_port):
        return "https://{host}:{port}/".format(host=appserver_host, port=appserver_port)

    @staticmethod
    def generate_rest_url_with_args(base_url, api_endpoint, **kwargs):
        """
        Generates a REST URL to execute by appending specified arguments

        Parameters:
            - base_url (str): Base URL for REST API (Refer RestGeneric.create_base_url)
            - api_endpoint (str): REST API endpoint
            - kwargs (dict): Arguments to append to url

        Returns:
            - str: REST api URL with arguments
        """
        url = base_url + api_endpoint
        if len(kwargs) == 0:
            return url
        url += "?"
        for k, v in iteritems(kwargs):
            v = str(v)
            url += "{key}={value}&".format(key=k, value=quote(v))
        url = url[:-1]
        return url

    @staticmethod
    def generate_rest_urls_from_excel(base_url, excel_file_loc, sheet_name):
        """
        Generates URLs for Test Case data stored in Excel sheet

        Parameters:
            - base_url (str): Base URL for REST API (Refer RestGeneric.create_base_url)
            - excel_file_loc (str): OS path of excel file
            - sheet_name (str): Sheet name to read from excel file

        Returns:
            - urls (dict): URL dictinory in format {'TC_ID' : 'URL to execute'}
        """
        df = pd.read_excel(ExcelFile(excel_file_loc), sheet_name, index_col=0, dtype=str)
        urls = {}
        for tc_id in df.index:
            api_url = df['Endpoint'][tc_id]
            params_dict = {}
            for param_name in df.columns[3:]:
                cell_value = df[param_name][tc_id]
                if str(cell_value) != 'nan':
                    k, v = param_name, cell_value
                    params_dict[k] = v
                urls[tc_id] = RestGeneric.generate_rest_url_with_args(base_url, api_url, **params_dict)
        return urls

    @staticmethod
    def execute_get_request(url, headers=None, authorization_key=None, auth_key_name=None):
        """
            Executes a HTTP GET request

            Parameters:
                - url (string): URL for POST request
                - header (dictionary): JSON formatted request body for POST request.
                    This is optional parameter if not provided it takes default parameters in headers.
                - authorization_key (string): authentication key, need to pass for authentication.
                    This authorization key can be received from session/login apis
                    This parameter is optional only for create session api

            Returns:
                - It returns dictionary with following items for validations
                    - response content
                    - response status code
                    - response header
        """
        if headers is None:
            headers = {
                "Content-Type": "application/json",
                "Accept": "*/*",
                "Accept-Encoding": "gzip, deflate",
                "Connection": "keep-alive"
            }
        if authorization_key is not None:
            if auth_key_name is None:
                headers["Authorization"] = authorization_key
            else:
                headers[auth_key_name] = authorization_key
        response = requests.get(url, headers=headers, verify=False)
        return response.content, response.status_code, response.headers

    @staticmethod
    def execute_post_request(url, request_body=None, headers=None, authorization_key=None, auth_key_name=None):
        """
            Executes a HTTP POST request
            Parameters:
                - url (string): URL for POST request
                - request_body (dictionary): JSON formatted request body for POST request
                - header (dictionary): JSON formatted request body for POST request.
                    This is optional parameter if not provided it takes default parameters in headers.
                - authorization_key (string): authentication key, need to pass for authentication.
                    This authorization key can be received from session/login apis
                    This parameter is optional only for create session api

            Returns:
                - It returns dictionary with following items for validations
                response content
                response status code
                response header
                response key: this will be as part of out put only when session/login api will be triggered
                else will not be part of out put.
        """
        if headers is None:
            headers = {
                "Content-Type": "application/json",
                "Accept": "*/*",
            }
        if authorization_key is not None:
            if auth_key_name is None:
                headers["Authorization"] = authorization_key
            else:
                headers[auth_key_name] = authorization_key
        response = requests.post(url, data=request_body, headers=headers, verify=False)
        if 'api/v1/sessions' in url:
            if auth_key_name is None:
                return response.content, response.status_code, response.headers, response.headers['Authorization']
            else:
                return response.content, response.status_code, response.headers, response.json()[auth_key_name]
        else:
            return response.content, response.status_code, response.headers

    @staticmethod
    def execute_put_request(url, request_body=None, headers=None, authorization_key=None, auth_key_name=None):
        """
            Executes a HTTP PUT request

            Parameters:
                - url (string): URL for POST request
                - request_body (dictionary): JSON formatted request body for POST request
                - header (dictionary): JSON formatted request body for POST request.
                    This is optional parameter if not provided it takes default parameters in headers.
                - authorization_key (string): authentication key, need to pass for authentication.
                    This authorization key can be received from session/login apis
                    This parameter is optional only for create session api

                Returns:
                - It returns dictionary with following items for validations
                    - response content
                    - response status code
                    - response header
        """
        if headers is None:
            headers = {
                "Content-Type": "application/json",
                "Accept": "*/*",
                "Accept-Encoding": "gzip, deflate",
                "Connection": "keep-alive"
            }
        if authorization_key is not None:
            if auth_key_name is None:
                headers["Authorization"] = authorization_key
            else:
                headers[auth_key_name] = authorization_key
        response = requests.put(url, data=request_body, headers=headers, verify=False)
        return response.content, response.status_code, response.headers

    @staticmethod
    def execute_patch_request(url, request_body=None, headers=None, authorization_key=None, auth_key_name=None):
        """
            Executes a HTTP PATCH request

            Parameters:
                - url (string): URL for POST request
                - request_body (dictionary): JSON formatted request body for POST request
                - header (dictionary): JSON formatted request body for POST request.
                    This is optional parameter if not provided it takes default parameters in headers.
                - authorization_key (string): authentication key, need to pass for authentication.
                    This authorization key can be received from session/login apis
                    This parameter is optional only for create session api

            Returns:
                - It returns dictionary with following items for validations
                    - response content
                    - response status code
                    - response header
        """
        if headers is None:
            headers = {
                "Content-Type": "application/json",
                "Accept": "*/*",
                "Accept-Encoding": "gzip, deflate",
                "Connection": "keep-alive"
            }
        if authorization_key is not None:
            if auth_key_name is None:
                headers["Authorization"] = authorization_key
            else:
                headers[auth_key_name] = authorization_key

        response = requests.patch(url, data=request_body, headers=headers, verify=False)
        return response.content, response.status_code, response.headers

    @staticmethod
    def execute_delete_request(url, headers=None, authorization_key=None, auth_key_name=None):
        """
            Executes a HTTP DELETE request

            Parameters:
                - url (string): URL for POST request
                - header (dictionary): JSON formatted request body for POST request.
                    This is optional parameter if not provided it takes default parameters in headers.
                - authorization_key (string): authentication key, need to pass for authentication.
                    This authorization key can be received from session/login apis
                    This parameter is optional only for create session api

            Returns:
                - It returns dictionary with following items for validations
                    - response content
                    - response status code
                    - response header
        """
        if headers is None:
            headers = {
                "Content-Type": "application/json",
                "Accept": "*/*",
                "Accept-Encoding": "gzip, deflate",
                "Connection": "keep-alive"
            }
        if authorization_key is not None:
            if auth_key_name is None:
                headers["Authorization"] = authorization_key
            else:
                headers[auth_key_name] = authorization_key
        response = requests.delete(url, headers=headers, verify=False)
        return response.content, response.status_code, response.headers

    @staticmethod
    def log_error(error_response):
        """
            Logs error response (json)

            Parameters:
                - error_response (dict): JSON object containing error details

            Returns:
                - error_resp (dict): Unmodified error_response
        """
        log.info("Error {} : {} \n{} \nPath: {}".format(error_response['status'], error_response['error'],
                                                        error_response['message'], error_response['path']))
        return error_response

    @staticmethod
    def get_value_by_key_from_json(json_data, key_path):
        """
        Get value of key specified by `key_path` from `json_data` object

        Parameters:
            - json_data (dict): JSON object from which value is to be extracted
            - key_path (str): Period ('.') separated json key path (eg. key1.key2.key3...)

        Returns:
            - object: Value specified by `key_path`
        """
        if isinstance(json_data, str):
            json_data = json.loads(json_data)
        key_path = key_path.split('.')
        try:
            value = reduce(operator.getitem, key_path, json_data)
        except KeyError as e:
            value = e.args[0]
        return value

    @staticmethod
    def delete_from_dictionary(json_data, *args):
        """
            Delete a key specified by `args` in `json_data` object

            Parameters:
                - json_data (dict): JSON object to which value is to be updated
                - args (*): Period ('.') separated json key paths

            Returns:
                - None
        """
        for arg in args:
            json_data_root = json_data
            keys = arg.split('.')
            for key in keys[:-1]:
                json_data = json_data.get(key, "Invalid Key path!")
                if json_data == "Invalid Key path!":
                    return json_data + arg
            del json_data[keys[-1]]
            json_data = json_data_root

    @staticmethod
    def set_value_by_key_in_json(json_data, key_path, value):
        """
        Set value of key specified by `key_path` in `json_data` object

        Parameters:
            - json_data (dict): JSON object to which value is to be updated
            - key_path (str): Period ('.') separated json key path (eg. key1.key2.key3...)

        Returns:
            - None
        """
        keys = key_path.split('.')
        for key in keys[:-1]:
            json_data = json_data.setdefault(key, {})
        json_data[keys[-1]] = value

    def _ordered(self, obj):
        """
        Returns an ordered tuple of JSON object

        Can be used to order <list>, <dict> objects individually

        Parameters:
            - obj (object): Object serialize in sorted order
        """
        if isinstance(obj, dict):
            return sorted((k, self._ordered(v)) for k, v in obj.items())
        if isinstance(obj, list):
            return sorted(self._ordered(x) for x in obj)
        else:
            return obj

    def validate_json(self, obj_to_validate, obj_for_reference, keys_to_skip="", parent='root'):
        """
            Validates `obj_to_validate` against `obj_for_reference`

            Parameters:
                - obj_to_validate (dict): Json object to validate
                - obj_for_reference (dict): Json object to validate against
                - keys_to_skip (str): Comma separated string of key names to skip during validation
                - parent (str): Name for parent JSON object (Default: 'root')

            Returns:
                - match (bool): `True` if objects match, `False` otherwise
                - mismatch (str): Summary of mismatching fields
        """
        match = True
        if isinstance(obj_to_validate, dict) and isinstance(obj_for_reference, dict):
            key_list_1 = sorted(obj_to_validate.keys())
            key_list_2 = sorted(obj_for_reference.keys())
            for key in key_list_2:
                if key not in keys_to_skip.split(','):
                    if key not in key_list_1:
                        match = False
                        self.mismatch.append('Missing key: {} -> {}'.format(parent, key))
                    else:
                        if key == 'device_type':
                            obj_to_validate[key] = obj_for_reference[key]
                        match = self.validate_json(obj_to_validate[key], obj_for_reference[key], keys_to_skip,
                                                   parent + ' -> ' + key)[0] and match
        elif isinstance(obj_to_validate, list) and isinstance(obj_for_reference, list):
            if len(obj_to_validate) > 0 and len(obj_for_reference) > 0:
                if isinstance(obj_for_reference[0], dict) and isinstance(obj_to_validate[0], dict):
                    key_to_sort = None
                    for key in obj_for_reference[0].keys():
                        if key in obj_to_validate[0].keys() and isinstance(obj_for_reference[0][key], int):
                            key_to_sort = key
                            break
                    if key_to_sort is None:
                        for key in obj_for_reference[0].keys():
                            if key in obj_to_validate[0].keys() and isinstance(obj_for_reference[0][key], str):
                                key_to_sort = key
                                break
                    obj_to_validate.sort(key=lambda x: x[key_to_sort])
                    obj_for_reference.sort(key=lambda x: x[key_to_sort])
                    for obj1_value, obj2_value in zip(obj_to_validate, obj_for_reference):
                        match = self.validate_json(obj1_value, obj2_value, keys_to_skip, parent)[0] and match
        else:
            if type(obj_to_validate) != type(obj_for_reference):
                match = False
                self.mismatch.append('Data types mismatch for key: {}'.format(parent))
            if str(obj_to_validate) != str(obj_for_reference):
                match = False
                self.mismatch.append('Values mismatch for key: {}'.format(parent))
        return match, '\n'.join(self.mismatch)

    @staticmethod
    def _create_filter(**kwargs):
        return lambda obj: all(RestGeneric.get_value_by_key_from_json(obj, k) == v for k, v in iteritems(kwargs))

    @staticmethod
    def get_filtered_object_list(list_of_objects, **filter_dict):
        """
            Get a filtered list of json objects

            Parameters:
                - list_of_objects (list): List of JSON objects
                - filter_dict (dict): Dictionary in the format {"key_path": value} used as filter

            Note:
                key_path should be in following format key1.key2.key3... (Refer: RestGeneric.get_value_by_key_from_json)

            Returns:
                list: list of objects filtered with respect to `filter_dict`
        """
        custom_filter_func = RestGeneric._create_filter(**filter_dict)
        return list(filter(custom_filter_func, list_of_objects))

    @staticmethod
    def load_json(json_str):
        """
            Load JSON string as json object <dict>
        """
        try:
            json_data = json.loads(json_str)
        except Exception as e:
            json_data = str(e)
            log.error(str(e))
        return json_data

    @staticmethod
    def find_element(element, *keys):
        """
        Check if *keys (nested) exists in `element` (dict).
        """
        if not isinstance(element, dict):
            raise AttributeError('keys_exists() expects dict as first argument.')
        if len(keys) == 0:
            raise AttributeError('keys_exists() expects at least two arguments, one given.')

        _element = element
        for key in keys:
            try:
                _element = _element[key]
            except KeyError:
                return False
        return True

    @staticmethod
    def get_week_number():
        """
               gets current week no if date is not passed. if date is passed it will give week no of that date.
        """
        week_number = date.today().isocalendar()[1]
        return week_number

    @staticmethod
    def get_catalog_and_server_smart_group(catalog_list, windows_server_group_list, linux_server_group_list):
        """
        This will return server groups and catalog details for given catalog
        """
        windows_server_group_list= json.loads(json.dumps(windows_server_group_list))
        linux_server_group_list = json.loads(json.dumps(linux_server_group_list))
        if not isinstance(catalog_list, list):
            raise AttributeError('expects list as first argument.')
        if not isinstance(windows_server_group_list, json):
            raise AttributeError('expects dict as 2nd argument.')
        if not isinstance(linux_server_group_list, json):
            raise AttributeError('expects dict as 3rd argument.')
        return catalog_list[0], catalog_list[1], catalog_list[2]

    @staticmethod
    def check_value_exist_in_json(json_data, value):
        """
        Get value of key specified by `key_path` from `json_data` object
        Parameters:
            - json_data (dict): JSON object from which value is to be extracted
            - value (str): search for value in json object
        Returns:
            - object: returns true or false if found/not found. throws exception if something goes wrong.
        """

        if isinstance(json_data, str):
            json_data = json.loads(json_data)
        try:
            return_value = value in json_data.values()
        except KeyError as e:
            return_value = e.args[0]
        return return_value

    @staticmethod
    def get_excel_column_data(excel_file_loc, sheet_name, column_name):
        """
        Gent Datafor specfic column values stored in Excel sheet

        Parameters:
        - excel_file_loc (str): OS path of excel file
        - sheet_name (str): Sheet name to read from excel file

        Returns:
            - Data (list): DataList in format {'Data'}
        """
        df = pd.read_excel(ExcelFile(excel_file_loc), sheet_name)
        data = df[column_name].tolist()
        rtn = [x for x in data if str(x) != 'nan']
        print(rtn)
        return rtn
    @staticmethod
    def get_csv_column_data(csv_file_loc, sheet_name, column_name):
        """
        Gent Data for specfic column values stored in csv sheet

        Parameters:
        - csv_file_loc (str): OS path of excel file
        - sheet_name (str): Sheet name to read from csv file

        Returns:
            - Data (list): DataList in format {'Data'}
        """
        df = pd.read_csv(csv_file_loc)
        data = df[column_name].tolist()
        rtn = [x for x in data if str(x) != 'nan']
        print(rtn)
        return rtn
