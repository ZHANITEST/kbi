/**
 *
 * kbi.or.kr ebook downloader
 *   - by 2018.07.22 / ZHANITEST(github.com/zhanitest)
 *   - License: GPLv3(gnu.org/licenses/gpl.txt)
 */

import std.stdio;
import std.file;
import std.string;
import std.net.curl;
import std.conv:to;
import std.zip;
import std.datetime.systime : SysTime, Clock;
import std.parallelism;

/**
 * Main 시작점
 * params:
 *  - args[]: 두번째는 교재코드, 세번째는 페이지의 리미트 값 입력
 *    ex) ./kbi Q91P41A53W79 399
 */
void main(string[] args)
{
	// 프로그램 시작 안내 프린트
	writeln("[kbi ebook downloader]");
	
	// 간단한 스크립트라서 range violation 검사는 안한다 ㅎ
	string base_url = "http://www.kbi.or.kr/kbidata/ebook/fdata/catImage/"~args[1]~"/s";
	int limit = to!int(args[2]);

	// 다운로드 리스트
	string[string][] list;
	for(int i=1; i<=limit; i++){
		string str = format("%.3s", i);         // zero fill formating
		string file_url = base_url~str~".jpg";  // and join str
		
		// 리스트 추가
		list ~= [
			"url"  : file_url,
			"name" : "s"~str~".jpg"
		];	
	}

	// 생성한 map리스트를 가지고 다운로드 병렬처리
	// ... 하려고 했으나 크래시 때문에 일단 싱글로
	writeln(">> download start!");
	foreach(e; list){
	//foreach(e; parallel(list) ){
		download( e["url"], e["name"] );
	}

	// 다운로드 완료 후 압축파일 생성
	writeln(">> make a zip file!");

	// 생성할 압축 오브젝트
	ZipArchive zip_obj = new ZipArchive();

	// 압축멤버 오브젝트 생성 후 압축멤버 추가
	foreach(e; list){
		// 압축멤버 생성
		ArchiveMember element_obj = new ArchiveMember();
		element_obj.name = e["name"]; // 압축 시 파일이름 넣어주기
		
		File f = File(e["name"], "rb");		// 압축할 파일을 열어
		
		
		auto fsize = 0;
		fsize = to!uint(f.size);			// (DMD와 LDC 차이 때문에 치트 추가 -_-a)				
		ubyte[] binary = new ubyte[fsize];  // 가져올 사이즈 정해서
		f.rawRead(binary); 					// 읽은 후
		f.close();							// 닫기

		element_obj.expandedData(binary);	// 바이너리 입력. expandedData는 private라 property.
		zip_obj.addMember(element_obj);		// 압축파일에 압축멤버 추가
		binary, element_obj = null;			// GC는 돌겠지만 일단 null 처리 ...
	}

	SysTime time_now = Clock.currTime();							// 현재 날짜로 zip파일명 생성
	std.file.write(time_now.toISOString()~".zip", zip_obj.build()); // 압축파일 출력

	// 받은 파일 모두 삭제
	writeln(">> Cleaning!");
	foreach(e; parallel(list)){
		// 실제 파일이 존재할 때 삭제
		if(exists(e["name"]) && isFile(e["name"])){
			remove(e["name"]);
		}
	}

	// 완료
	writeln(">> Done!");
}