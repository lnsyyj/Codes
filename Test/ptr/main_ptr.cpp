#include <memory>
#include <iostream>
#include <string>

using namespace std;

class A{
public:
	A(){
		cout << "A()" << endl;
	}
	A(const string& str):m_str(str){
		cout << "A(const string& str)" << endl;
	}
	~A(){
		cout << "~A()" << endl;
	}

	void print(){
		cout << m_str << endl;
	}
private:
	string m_str;
};


int main(){
	//shared_ptr
	shared_ptr<A> sPtr(new A("i am shared_ptr"));
	sPtr->print();
	
	//unique_ptr c++11 代替 auto_ptr
	unique_ptr<A> uPtr(new A("i am unique_ptr"));
	uPtr->print();
	
	//weak_ptr
	
	
	//auto_ptr c++11已弃用
	auto_ptr<A> aPtr(new A("i am auto_ptr"));
	aPtr->print();

	return 0;
}