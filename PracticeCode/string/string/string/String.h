#pragma once

class String
{
public:
	String(const char* cstr = 0);
	String(const String& str);	//拷贝构造，类带指针一定要写
	String& operator=(const String& str);	//拷贝赋值，类带指针一定要写
	~String();
	char* get_c_str() const { return m_data; }
private:
	char* m_data;
};