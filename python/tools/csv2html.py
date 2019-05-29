#!/usr/bin/env python3

import argparse
import csv
import sys
import json
import pathlib

class clsCSV2HTML:
    dictOpt = None
    _dictColor = None
    strOverwrite=" This value will overwrite -j option for the same option."
    
    def __init__(self):
        self.dictOpt = {}
        self._dictColor = {'row':{}, 'col':{}, 'key':{}}
    
    def parseJson(self, strJson):
        if self._checkFile(strJson) is True:
            with open(strJson, "r") as jsonfile:
                try:
                    self.dictOpt = json.loads(jsonfile.read())
                except json.JSONDecodeError as err:
                    print("Json format error, please check: " + strJson)
                    print(err)
                    return False
        return True
    
    def _checkFile(self, objFile):
        if objFile is None:
            return False
        elif type(objFile) is 'list':
            for strFilename in objFile:
               if pathlib.Path(strFilename).exists() is False:
                   return False
        elif type(objFile) is 'str':
            if pathlib.Path(objFile).exists() is False:
                return False
        return True
    
    def _checkArgsOverwrite(self,strKey, dictOpt, dictJson, isMust=False):
        ret = None
        if strKey in dictOpt and dictOpt[strKey] is not None:
            ret = dictOpt[strKey]
        elif dictJson is None:
            pass
        elif strKey in dictJson and dictJson[strKey] is not None:
            ret = dictJson[strKey]
        if isMust is True and ret is None:
            print('Miss "' + strKey + '" in json/option, tool couldn\'t work , please check your json/option')
        return ret
    
    def parseOption(self):
        parser = argparse.ArgumentParser(description='Tools convert CSV file to HTML table file.', 
                                         add_help=True, epilog='Contact: zelgadiss@163.com',
                                         formatter_class=argparse.RawTextHelpFormatter)
        parser.add_argument('-j', '--jsonfile', type=str,
                            help='''setup spec display effect by filename, this value is format value, string format is json
file example:
{
    "filename":"CSV File name",
    "full": true, "output": "htmlFileName", "title": true, "Caption": "Test", "border": 1,
    "color": [
        { "type": "keyword", "value": "Pass", "font": "green", "background": "green"},
        { "type": "key", "value": "Fail", "font": "red"},
        { "type": "row", "value": 1, "font": "blue", "background": "red"},
        { "type": "column", "value": 2, "font": "brown"},
        { "type": "col", "value": 4, "background": "#0000FF"}
        ]
}
    ''')
        parser.add_argument('filename', type=str, help='csv file name.' + self.strOverwrite)
        parser.add_argument('-t', '--title', action='store_true', help='csv file 1st line is the title.' + self.strOverwrite)
        parser.add_argument('-o', '--output', type=str, help='output html file name, default: stdout.' + self.strOverwrite, default=sys.stdout)
        parser.add_argument('-c', '--color', type=str, nargs='+', help='''setup spec color, this value is format value, string format is json
This value will overwrite -j option for the same option
'type': value type [ keyword/key, row, column/col];
'value': type mapping value [ INT: row & column, STR: keyword];
'font': font color [ html support color name/HEX value];
'background': font color [ html support color name/HEX value];
the display effect is key > col > row
for example
{ "type": "keyword", "value": "Pass", "font": "green", "background": "green"}
''' + self.strOverwrite)
        parser.add_argument('-f', '--full', action='store_true', help='output table <table>.' + self.strOverwrite)
        parser.add_argument('-C', '--Caption', type=str, help='output table <caption> tag.' + self.strOverwrite)
        parser.add_argument('-b', '--border', type=int, help='control table border, need work with -f option, default:1' + self.strOverwrite, default=1)
        parser.add_argument('--version', action='version', version='%(prog)s 1.0')
        
        ret_args = vars(parser.parse_args())
        
        if self.parseJson(ret_args['jsonfile']) is False:
            return False
        
        # verify for the option value
        self.dictOpt['filename'] = self._checkArgsOverwrite('filename', ret_args, self.dictOpt, True)
        self.dictOpt['title'] = self._checkArgsOverwrite('title', ret_args, self.dictOpt)
        self.dictOpt['output'] = self._checkArgsOverwrite('output', ret_args, self.dictOpt)
        self.dictOpt['color'] = self._checkArgsOverwrite('color', ret_args, self.dictOpt)
        self.dictOpt['full'] = self._checkArgsOverwrite('full', ret_args, self.dictOpt)
        self.dictOpt['Caption'] = self._checkArgsOverwrite('Caption', ret_args, self.dictOpt)
        self.dictOpt['border'] = self._checkArgsOverwrite('border', ret_args, self.dictOpt)
        
        return True
    
    def _setupParameterDefault(self, strOption, objDef = None):
        if strOption not in self.dictOpt:
            self.dictOpt[strOption] = objDef
    
    def _filterColorDcit(self, dictColor):
        if type(dictColor) is not dict:
            return
        elif 'type' not in dictColor or 'value' not in dictColor:
            return
        elif type(dictColor['type']) is not str or type(dictColor['value']) is not str:
            return
        elif dictColor['type'] not in ['key', 'keyword', 'row', 'col', 'column']:
            return
        
        if dictColor['type'][0:3] == 'key':
            self._addColorDict(self._dictColor['key'], dictColor)
        if dictColor['type'] == 'row':
            self._addColorDict(self._dictColor['row'], dictColor)
        if dictColor['type'][0:3] == 'col':
            self._addColorDict(self._dictColor['col'], dictColor)
    
    def _addColorDict(self, dictOutput, dictTarget):
        dictTmp = {}
        if 'font' in dictTarget and dictTarget['font'] is not None:
            dictTmp['font'] = dictTarget['font']
        if 'background' in dictTarget and dictTarget['background'] is not None:
            dictTmp['background'] = dictTarget['background']
        if 'font' in dictTmp or 'background' in dictTmp:
            dictOutput[dictTarget['value']]=dictTmp

    def _formatJsonColor(self, dictJson):
        if dictJson is None:
            return
        if type(dictJson) is list:
            for dictColor in dictJson:
                self._filterColorDcit(dictColor)
        elif type(dictJson) is dict:
            self._filterColorDcit(dictColor)
    
    def _checkParameter(self):
        if 'filename' not in self.dictOpt:
            print('Miss CSV file operation, please check json string')
            return False
        elif self._checkFile(self.dictOpt['filename']) is False:
            print('Miss CSV file in current system, please check json/option:' + self.dictOpt['filename'])
            return False
        
        self._setupParameterDefault('title', False)
        self._setupParameterDefault('output')
        self._setupParameterDefault('color')
        self._setupParameterDefault('full', False)
        self._setupParameterDefault('Caption')
        self._setupParameterDefault('border', 1)

        self._formatJsonColor(self.dictOpt['color'])
        
        return True
    
    def _outputHtmlStyleColor(self, dictColor):
        strRetLine=" style=\""
        if 'background' in dictColor:
            strRetLine+="background-color:" + dictColor['background'] + ";"
        if 'font' in dictColor:
            strRetLine+="color:" + dictColor['font'] + ";"
        strRetLine+="\""
        return strRetLine
    
    def _outputCol(self, objUnit, intColIdx, strTag = 'td'):
        if objUnit is None:
            objUnit='&nbsp;'
        strRetLine = '<' + strTag
        if objUnit.strip() in self._dictColor['key']:
            strRetLine += self._outputHtmlStyleColor(self._dictColor['key'][objUnit.strip()])
        elif intColIdx in self._dictColor['col']:
            strRetLine += self._outputHtmlStyleColor(self._dictColor['col'][intColIdx])
        strRetLine += '>' + objUnit.strip().replace(' ', '&nbsp;') + '</' + strTag + '>'
        return strRetLine
    
    def _outputRowHead(self, intRowIdx):
        strRetLine = "<tr"
        if intRowIdx in self._dictColor['row']:
            strRetLine += self._outputHtmlStyleColor(self._dictColor['row'][intRowIdx])
        strRetLine += ">"
        return strRetLine
        
    def _outputCSV2HTML(self, strFileName):
        strRetLine=""
        intCurRow=0
        
        try:
            with open(strFileName) as csvfile:
                #strRetLine += "<thead>"
                if self.dictOpt['title'] is True:
                    intCurRow = 1
                    reader = csv.DictReader(csvfile)
                    strRetLine += self._outputRowHead(intCurRow)
                    intCurCol = 1
                    for key in reader.fieldnames:
                        if key is None:
                            continue
                        strRetLine += self._outputCol(key, intCurCol, 'th')
                        intCurCol += 1
                    strRetLine += "</tr>"
                else:
                    reader = csv.reader(csvfile)
                #strRetLine += "</thead>\n"
                #strRetLine += "<tbody>\n"
                
                for row in reader:
                    intCurRow += 1
                    strRetLine += self._outputRowHead(intCurRow)
                    intCurCol=1
                    if self.dictOpt['title'] is True:
                        for key in reader.fieldnames:
                            if key is None:
                                continue
                            strRetLine += self._outputCol(row[key], intCurCol)
                            intCurCol += 1
                    else:
                        for i in row:
                            strRetLine += self._outputCol(i, intCurCol)
                            intCurCol += 1
                    strRetLine += "</tr>\n"
                #strRetLine += "</tbody>\n"
        except csv.Error as err:
            print("Catch CSV parse Error")
            print(err)
        
        return strRetLine

    def outputHTML(self):
        if self._checkParameter() is False:
            return False
        
        output_line = ""
        if self.dictOpt['full'] is True:
            output_line += "<table border=\"" + str(self.dictOpt['border']) + "\">\n"

        if self.dictOpt['Caption'] is not None:
            output_line += "<caption>" + self.dictOpt['Caption'] + "</caption>\n"
        
        output_line += self._outputCSV2HTML(self.dictOpt['filename'])

        if self.dictOpt['full'] is True:
            output_line += "</table>\n"

        if self.dictOpt['output'] != sys.stdout:
            with open(self.dictOpt['output'], "a+") as f:
                f.write(output_line)
        else:
            sys.stdout.write(output_line)
        return True
    
    def dumpOptJson(self):
        strRetLine = ""
        if self.dictOpt['output'] == sys.stdout:
            self.dictOpt['output'] = 'sys.stdout'
            strRetLine = json.dumps(self.dictOpt)
            self.dictOpt['output'] = sys.stdout
        else:
            strRetLine = json.dumps(self.dictOpt)
        return strRetLine
                    

if __name__ == "__main__":
    csv2html = clsCSV2HTML()
    if csv2html.parseOption() is True:
        if csv2html.outputHTML() is True:
            exit(0)
    exit(1)
