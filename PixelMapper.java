import java.util.Scanner;

class PixelMapper {

	public static void main(String[] args){
		Scanner in = new Scanner(System.in);
		int a = 1;
		int b = 2;
		double f = 1.0;
		int aPtr;
		int [] arrA, arrB;
		
		System.out.println("Enter numbers");

		while(a > 0 && b > 0){
			a = in.nextInt();
			b = in.nextInt();
			
			if(a > 0 && b > 0){
				aPtr = 0;
				f = b * 1.0/a;
				double n = 0; // number of times to use a pixel from a in b
				System.out.printf("a:%d b:%d b/a:%.3f\n", a, b, f);
				if(f<1){
					continue;//todo handle a > b
				}
				for(int i = 0; i < a; i++){
					n += f;
					while(n > 1.0){
						System.out.print(aPtr + " ");
						n -= 1.0;
					}
					aPtr++;
				}
				if(n >= 1.0){
					System.out.print(aPtr + " ");
				}
				System.out.printf("n:%.3f", n);
			}
			System.out.println();
		}
		System.out.println("done");
	}
}
