#pragma once

class String
{
public:
	String(const char* cstr = 0);
	String(const String& str);	//�������죬���ָ��һ��Ҫд
	String& operator=(const String& str);	//������ֵ�����ָ��һ��Ҫд
	~String();
	char* get_c_str() const { return m_data; }
private:
	char* m_data;
};