#pragma once
class complex
{
public:
	complex(double r = 0, double i = 0) :re(r), im(i) { }

	complex& operator += (const complex&);

	double real() const { return re; }
	double imag() const { return im; }
private:
	double re, im;

	friend complex& __doapl(complex*, const complex&);
};